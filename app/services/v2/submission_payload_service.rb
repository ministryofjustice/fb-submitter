module V2
  class SubmissionPayloadService
    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def submission_id
      payload['submission_id']
    end

    def submission_at
      date_string = payload.dig('meta', 'submission_at')
      return Time.zone.now if date_string.blank?

      Time.zone.parse(date_string)
    end

    def reference_number
      payload.dig('meta', 'reference_number')
    end

    def user_answers
      payload['pages'].each_with_object({}) do |page, hash|
        page['answers'].each do |answer|
          hash[answer['field_id']] = answer['answer']
        end
      end
    end

    def attachments
      payload[:attachment]
      # payload.dig('meta', 'attachments')
    end
  end
end
