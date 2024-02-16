require 'csv'
require 'tempfile'

module V2
  class GenerateCsvContent
    DATA_UNAVAILABLE = 'Data not available in CSV format'.freeze
    FIELD_SEPARATOR = '/'.freeze

    def initialize(payload_service:)
      @payload_service = payload_service
    end

    def execute
      tmp_csv = generate_temp_file
      generate_attachment_object(tmp_csv)
    end

    private

    attr_reader :payload_service

    def generate_temp_file
      tmp_csv = Tempfile.new

      CSV.open(tmp_csv.path, 'w') do |csv|
        csv_contents.each { |row| csv << row }
      end

      tmp_csv.rewind
      tmp_csv
    end

    def csv_contents
      return @csv_contents if @csv_contents

      @csv_contents = []
      @csv_contents << csv_headers
      @csv_contents << csv_data
    end

    def answer_values
      payload_service.user_answers.values.map do |answer|
        if answer.is_a?(Array)
          DATA_UNAVAILABLE
        else
          values = answer.is_a?(Hash) ? answer.values : [answer]
          values.each { |v| v.gsub!(/\R+/, ' ') }
        end
      end
    end

    def csv_data
      data = []

      data << submission_reference
      data << payload_service.submission_at.iso8601(3)
      data.concat(answer_values.flatten)

      data
    end

    def csv_headers
      headers = []

      payload_service.user_answers.each do |field_id, answer|
        headers << if answer.is_a?(Hash)
                     answer.keys.map { |answer_id| [field_id, answer_id].join(FIELD_SEPARATOR) }
                   else
                     field_id
                   end
      end

      [first_heading, 'submission_at', headers].flatten
    end

    def generate_attachment_object(tmp_csv)
      attachment = Attachment.new(
        filename: "#{submission_reference}-answers_OFFICIAL-SENSITIVE.csv",
        mimetype: 'text/csv'
      )
      attachment.file = tmp_csv
      attachment
    end

    def first_heading
      payload_service.reference_number.present? ? 'reference_number' : 'submission_id'
    end

    def submission_reference
      @submission_reference ||=
        payload_service.reference_number || payload_service.submission_id
    end
  end
end
