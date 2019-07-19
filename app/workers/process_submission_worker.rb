class ProcessSubmissionWorker
  include Sidekiq::Worker

  def perform(submission_id)
    echo "Running"
    # service = ProcessSubmissionService.new(submission_id: submission_id)
    # service.perform
  end
end
