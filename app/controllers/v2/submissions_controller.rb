module V2
  class SubmissionsController < ActionController::API
    include Concerns::ContentNegotiation
    include Concerns::V2ErrorHandling
    before_action ::Filters::AuthenticateApplication
    before_action ::Filters::ValidateEncryptedSubmission
    before_action ::Filters::ValidateSchema

    def create
      @submission = Submission.create!(
        payload: SubmissionEncryption.new.encrypt(decrypted_submission),
        access_token:,
        service_slug: submission_params[:service_slug],
        encrypted_user_id_and_token: submission_params[:encrypted_user_id_and_token]
      )

      V2::ProcessSubmissionJob.perform_later(
        submission_id: @submission.id, request_id:
      )

      render json: {}, status: :created
    end

    private

    def submission_params
      params.slice(
        :encrypted_submission,
        :service_slug,
        :encrypted_user_id_and_token
      ).permit!
    end

    def access_token
      request.authorization.to_s.gsub(/^Bearer /, '')
    end

    def request_id
      request.request_id
    end

    def encrypted_submission
      submission_params[:encrypted_submission]
    end

    def decrypted_submission
      @decrypted_submission ||=
        SubmissionEncryption.new.decrypt(encrypted_submission)
    end
  end
end
