module V2
  class SubmissionPayloadService
    attr_reader :submission

    def initialize(submission)
      @submission = submission
    end

    delegate :encrypted_user_id_and_token, :access_token, to: :submission

    def payload
      @payload ||=
        submission.decrypted_submission.merge('submission_id' => submission.id)
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
      payload['attachments']
    end

    def actions
      payload['actions']
    end
  end
end
