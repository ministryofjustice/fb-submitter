require 'rails_helper'

describe JsonWebhookService do
  subject(:service) do
    described_class.new(
      webhook_attachment_fetcher:,
      webhook_destination_adapter:
    )
  end

  let(:submission) { create(:submission) }
  let(:submission_id) { '5de849f3-bff4-4f10-b245-23b1435f1c70' }

  let(:user_answers) do
    {
      first_name: 'bob',
      last_name: 'madly',
      submissionDate: 1_571_756_381_535,
      submissionId: submission_id
    }
  end

  let(:webhook_destination_adapter) { instance_spy(Adapters::JweWebhookDestination) }
  let(:webhook_attachment_fetcher) { instance_spy(WebhookAttachmentService) }

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
      submissionId: submission_id,
      submissionAnswers: user_answers,
      attachments:
    }.to_json
  end

  before do
    allow(webhook_destination_adapter).to receive(:send_webhook)
    allow(webhook_attachment_fetcher).to receive(:execute).and_return(attachments)
    service.execute(
      user_answers:, service_slug: submission.service_slug, payload_submission_id: submission_id
    )
  end

  it 'modifies and sends the submission to the destination' do
    expect(webhook_destination_adapter).to have_received(:send_webhook)
      .with(body: json_payload)
      .once
  end

  it 'calls the webhook_attachment_fetcher' do
    expect(webhook_attachment_fetcher).to have_received(:execute).once
  end
end
