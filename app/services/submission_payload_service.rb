require 'active_support/core_ext/hash'

class SubmissionPayloadService
  attr_reader :attachments, :actions, :submission, :submission_id, :payload

  def initialize(payload)
    @payload = payload.with_indifferent_access
    @attachments = @payload.fetch(:attachments)
    @actions = @payload.fetch(:actions)
    @submission = @payload.fetch(:submission)
    @submission_id = @payload.fetch(:submission).fetch('submission_id')
  end

  def user_answers_map
    questions = {}
    submission.fetch('sections', []).each do |section|
      section.fetch('questions').each do |question|
        questions[question.fetch('key')] = question.fetch('answer', nil)
      end
    end
    questions
  end
end
