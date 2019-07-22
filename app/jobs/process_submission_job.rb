class ProcessSubmissionJob < ApplicationJob
  queue_as :default

  def perform(submission_id)
    p 'resqueeeeeeeee'
    service = ProcessSubmissionService.new(submission_id)
    service.perform
  end
end
