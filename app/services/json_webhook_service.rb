class JsonWebhookService
  def initialize(webhook_attachment_fetcher:, webhook_destination_adapter:)
    @webhook_attachment_fetcher = webhook_attachment_fetcher
    @webhook_destination_adapter = webhook_destination_adapter
  end

  def execute(user_answers:, service_slug:, submission_id:)
    webhook_destination_adapter.send_webhook(
      body: {
        "serviceSlug": service_slug,
        "submissionId": submission_id,
        "submissionAnswers": user_answers,
        "attachments": webhook_attachment_fetcher.execute
      }.to_json
    )
  end

  private

  attr_reader :webhook_destination_adapter, :webhook_attachment_fetcher
end
