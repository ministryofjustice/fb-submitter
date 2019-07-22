class ProcessSubmissionWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(submission_id)
    ActiveRecord::Base.uncached do
      service = ProcessSubmissionService.new(submission_id)
      service.perform
    end
  end
end
