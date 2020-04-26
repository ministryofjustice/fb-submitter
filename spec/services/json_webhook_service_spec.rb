require 'rails_helper'

describe JsonWebhookService do
  def execute_json_webhook_service
    service.execute(
      user_answers: user_answers,
      service_slug: submission.service_slug,
      submission_id: submission.decrypted_payload[:submission_id],
      url: 'some-url',
      key: 'some-key'
    )
  end

  subject(:service) do
    described_class.new(
      webhook_attachment_fetcher: webhook_attachment_fetcher,
      webhook_destination_adapter: webhook_destination_adapter
    )
  end

  let(:submission) { create(:submission) }

  let(:user_answers) do
    {
      first_name: 'bob',
      last_name: 'madly',
      submissionDate: 1_571_756_381_535,
      submissionId: '5de849f3-bff4-4f10-b245-23b1435f1c70'
    }
  end

  let(:webhook_attachment_fetcher) { instance_spy(WebhookAttachmentService) }
  let(:webhook_destination_adapter) { Adapters::JweWebhookDestination }
  let(:webhook_destination_adapter_double) do
    object_double(Adapters::JweWebhookDestination.new(execution_payload), perform: nil)
  end

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

  let(:execution_payload) do
    {
      url: 'some-url',
      key: 'some-key',
      body: json_payload
    }
  end

  let(:json_payload) do
    {
      serviceSlug: submission.service_slug,
      submissionId: submission.decrypted_payload[:submission_id],
      submissionAnswers: user_answers,
      attachments: attachments
    }.to_json
  end

  before do
    Delayed::Worker.delay_jobs = false
    allow(webhook_attachment_fetcher).to receive(:execute).and_return(attachments)
    allow(Delayed::Job).to receive(:enqueue)
  end

  after do
    Delayed::Worker.delay_jobs = true
  end

  # rubocop:disable RSpec/MessageSpies
  it 'modifies and sends the submission to the destination' do
    expect(Delayed::Job).to receive(:enqueue).with(webhook_destination_adapter_double)
    expect(webhook_destination_adapter).to receive(:new)
      .with(execution_payload)
      .and_return(webhook_destination_adapter_double)

    execute_json_webhook_service
  end

  it 'calls the webhook_attachment_fetcher' do
    expect(webhook_attachment_fetcher).to receive(:execute).once

    execute_json_webhook_service
  end
  # rubocop:enable RSpec/MessageSpies
end
