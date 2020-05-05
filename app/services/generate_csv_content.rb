require 'csv'
require 'tempfile'
require_relative '../value_objects/attachment'

class GenerateCsvContent
  def initialize(payload_service:)
    @payload_service = payload_service
  end

  def execute
    tmp_csv = generate_temp_file
    generate_attachment_object(tmp_csv)
  end

  private

  def csv_contents
    return @csv_contents if @csv_contents

    @csv_contents = []
    @csv_contents << csv_headers
    @csv_contents << csv_data
  end

  def action
    payload_service.actions.find { |hash| hash[:type] && hash[:type] == 'csv' }
  end

  def keys_to_reject
    %w[submissionId submissionDate]
  end

  def answer_keys
    action[:user_answers].reject { |k, _| keys_to_reject.include?(k) }.keys
  end

  def answer_values
    array = action[:user_answers].reject { |k, _| keys_to_reject.include?(k) }.values

    array.map do |e|
      if e.is_a?(Hash) || e.is_a?(Array)
        'data not available in CSV format'
      else
        e
      end
    end
  end

  def csv_data
    data = []

    data << payload_service.submission_id
    data << payload_service.submission_at.iso8601(3)
    data.concat(answer_values)

    data
  end

  def csv_headers
    fixed_headers = %w[submission_id submission_at]
    dynamic_headers = answer_keys

    fixed_headers + dynamic_headers
  end

  def generate_temp_file
    tmp_csv = Tempfile.new

    CSV.open(tmp_csv.path, 'w') do |csv|
      csv_contents.each do |row|
        csv << row
      end
    end

    tmp_csv.rewind
    tmp_csv
  end

  def generate_attachment_object(tmp_csv)
    attachment = Attachment.new(
      filename: "#{payload_service.submission_id}-answers.csv",
      mimetype: 'text/csv',
      size: File.size(tmp_csv.path)
    )
    attachment.file = tmp_csv
    attachment
  end

  attr_reader :payload_service
end
