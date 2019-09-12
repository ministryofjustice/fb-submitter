class JsonWebhookService
  def initialize(runner_callback_adapter:, webhook_destination_adapter:, service_slug:)
    @runner_callback_adapter = runner_callback_adapter
    @webhook_destination_adapter = webhook_destination_adapter
    @service_slug = service_slug
  end

  def execute()
    webhook_destination_adapter.send_webhook(body: response)
  end

  private

  attr_reader :runner_callback_adapter, :webhook_destination_adapter

  def response
    submission_answers = JSON.parse(runner_callback_adapter.fetch_full_submission)
    {
      "serviceSlug": @service_slug,
      "submissionId": submission_answers['submissionId'],
      "submissionAnswers": submission_answers.except('submissionId')
    }.to_json
  end
end
