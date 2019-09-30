require 'rails_helper'

describe JsonWebhookService do
  subject(:service) do
    described_class.new(
      runner_callback_adapter: runner_callback_adapter,
      webhook_attachment_fetcher: webhook_attachment_fetcher,
      webhook_destination_adapter: webhook_destination_adapter
    )
  end

  let(:submission) { create(:submission) }

  let(:runner_callback_adapter) { instance_spy(Adapters::RunnerCallback) }
  let(:webhook_destination_adapter) { instance_spy(Adapters::JweWebhookDestination) }
  let(:webhook_attachment_fetcher) { instance_spy(WebhookAttachmentService) }

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
    allow(runner_callback_adapter).to receive(:fetch_full_submission).and_return(frontend_response)
  end

  it 'modifies and sends the submission to the destination' do
    service.execute(service_slug: submission.service_slug)

    expect(webhook_destination_adapter).to have_received(:send_webhook)
      .with(body: json_payload)
      .once
  end

  it 'calls fetch_full_submission' do
    service.execute(service_slug: submission.service_slug)
    expect(runner_callback_adapter).to have_received(:fetch_full_submission)
  end

  it 'calls the webhook_attachment_fetcher' do
    service.execute(service_slug: submission.service_slug)
    expect(webhook_attachment_fetcher).to have_received(:execute).once
  end
end
