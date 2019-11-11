class SubmissionController < ApplicationController
  def create
    @submission = Submission.create!(
      submission_params.merge(
        payload: EncryptionService.new.encrypt(payload)
      )
    )

    Delayed::Job.enqueue(
      ProcessSubmissionService.new(submission_id: @submission.id),
      run_at: 3.seconds.from_now
    )

    render status: :created
  end

  private

  def submission_params
    params.slice(
      :service_slug,
      :encrypted_user_id_and_token
    ).permit!
  end

  def payload
    params.slice(
      :actions,
      :submission,
      :attachments
    ).permit!
  end
end
