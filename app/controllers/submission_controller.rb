class SubmissionController < ApplicationController
  def create
    @submission = Submission.create(
      submission_params.merge(
        status: Submission::STATUS[:queued],
        payload: payload
      )
    )
    Delayed::Job.enqueue(
      ProcessSubmissionService.new(submission_id: @submission.id),
      run_at: 3.seconds.from_now
    )

    render status: :created
  end

  def show
    @submission = Submission.find(params[:id])
    render json: @submission, status: :ok
  end

  private

  def submission_params
    # we must use slice(..).permit! rather than permitting individual params, as
    # submission_details is an arbitrary hash, which AC Strong Params *really*
    # doesn't like
    params.slice(
      :service_slug,
      :encrypted_user_id_and_token,
      :submission_details
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
