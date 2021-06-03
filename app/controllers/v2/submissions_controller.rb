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
        access_token: access_token,
        service_slug: submission_params[:service_slug]
      )

      V2::ProcessSubmissionJob.perform_later(
        submission_id: @submission.id
      )

      render json: {}, status: :created
    end

    def submission_params
      params.slice(
        :encrypted_submission,
        :service_slug
      ).permit!
    end

    def access_token
      request.authorization.to_s.gsub(/^Bearer /, '')
    end

    def decrypted_submission
      @decrypted_submission ||=
        SubmissionEncryption.new.decrypt(
          submission_params[:encrypted_submission]
        )
    end
  end
end
