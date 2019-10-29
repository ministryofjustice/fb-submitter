class JsonWebhookService
  def initialize(webhook_attachment_fetcher:, webhook_destination_adapter:)
    @webhook_attachment_fetcher = webhook_attachment_fetcher
    @webhook_destination_adapter = webhook_destination_adapter
  end

  def execute(submission:, service_slug:)
    webhook_destination_adapter.send_webhook(
      body: build_payload(
        submission: submission,
        service_slug: service_slug,
        attachments: webhook_attachment_fetcher.execute
      )
    )
  end

  private

  attr_reader :webhook_destination_adapter, :webhook_attachment_fetcher

  def build_payload(service_slug:, attachments:, submission:)
    {
      "serviceSlug": service_slug,
      "submissionId": submission.fetch('submission_id', nil),
      "submissionAnswers": submission.except('submissionId'),
      "attachments": attachments
    }.to_json
  end
end
