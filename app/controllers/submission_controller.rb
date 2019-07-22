class SubmissionController < ApplicationController
  def create
    @submission = Submission.new(
      submission_params(params).merge(status: Submission::STATUS[:queued])
    )
    @submission.save!
    ProcessSubmissionWorker.perform_async(@submission.id)
    # ProcessSubmissionJob.perform_later(@submission.id)
    render status: :created, json: @submission
  end

  def show
    @submission = Submission.find(params[:id])
    render json: @submission, status: :ok
  end

  private

  def submission_params(opts=params)
    # we must use slice(..).permit! rather than permitting individual params, as
    # submission_details is an arbitrary hash, which AC Strong Params *really*
    # doesn't like
    opts.slice(
      :service_slug,
      :encrypted_user_id_and_token,
      :submission_details
    ).permit!
  end
end
