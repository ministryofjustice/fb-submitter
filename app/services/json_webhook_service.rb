class JsonWebhookService
  def initialize(runner_callback_adapter:, webhook_destination_adapter:)
    @runner_callback_adapter = runner_callback_adapter
    @webhook_destination_adapter = webhook_destination_adapter
  end

  def execute(service_slug:)
    webhook_destination_adapter.send_webhook(body: build_payload(service_slug))
  end

  private

  attr_reader :runner_callback_adapter, :webhook_destination_adapter

  def build_payload(service_slug)
    {
      "serviceSlug": service_slug,
      "submissionId": submission_answers['submissionId'],
      "submissionAnswers": submission_answers.except('submissionId')
    }.to_json
  end

  def submission_answers
    @submission_answers ||= JSON.parse(runner_callback_adapter.fetch_full_submission)
  end
end
