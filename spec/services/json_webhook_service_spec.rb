require 'rails_helper'

describe JsonWebhookService do
  let(:submission) { create(:submission) }
  let(:runner_callback_adapter) do
    instance_double(Adapters::RunnerCallback)
  end
  let(:webhook_destination_adapter) do
    instance_double(Adapters::JweWebhookDestination)
  end

  let(:webhook_attachment_fetcher) do
    instance_double(WebhookAttachmentService)
  end

  subject do
    described_class.new(
      runner_callback_adapter: runner_callback_adapter,
      webhook_attachment_fetcher: webhook_attachment_fetcher,
      webhook_destination_adapter: webhook_destination_adapter
    )
  end

  let(:frontend_response) { submission.submission_details.to_json }

  let(:attachments) do
    [
      {
        'url': 'example.com/public_url_1',
        'key': 'somekey1'
      },
      {
        'url': 'example.com/public_url_2',
        'key': 'somekey2'
      }
    ]
  end

  let(:json_payload) do
    {
      serviceSlug: submission.service_slug,
      submissionId: submission.submission_details['submissionId'],
      submissionAnswers: submission.submission_details.except('submissionId'),
      attachments: attachments
    }.to_json
  end

  before do
    allow(webhook_destination_adapter).to receive(:send_webhook)
    allow(webhook_attachment_fetcher).to receive(:execute).and_return(attachments)
    expect(runner_callback_adapter).to receive(:fetch_full_submission).and_return(frontend_response)
  end

  it 'modifies and sends the submission to the destination' do
    expect(webhook_destination_adapter).to receive(:send_webhook)
      .with(body: json_payload)
      .once

    subject.execute(service_slug: submission.service_slug)
  end

  it 'calls the webhook_attachment_fetcher' do
    expect(webhook_attachment_fetcher).to receive(:execute).once
    subject.execute(service_slug: submission.service_slug)
  end
end
