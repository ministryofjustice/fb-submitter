class SubmissionController < ApplicationController
  def create
    @submission = Submission.create!(
      submission_params.merge(
        payload: EncryptionService.new.encrypt(payload),
        access_token: access_token
      )
    )

    ProcessSubmissionService.new(submission_id: @submission.id).process

    render json: {}, status: :created
  end

  private

  def submission_params
    params.slice(
      :service_slug,
      :encrypted_user_id_and_token
    ).permit!
  end

  def access_token
    request.headers['x-access-token-v2']
  end

  def payload
    params.slice(
      :meta,
      :actions,
      :submission,
      :attachments
    ).permit!
  end
end
