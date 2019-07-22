class ProcessSubmissionWorker
  include Sidekiq::Worker

  def perform(submission_id)
    p 'xxxyyy'
    service = ProcessSubmissionService.new(submission_id)
    service.perform
  end
end
