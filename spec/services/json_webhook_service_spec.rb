require 'rails_helper'

describe JsonWebhookService do
  subject(:service) do
    described_class.new(
      webhook_attachment_fetcher: webhook_attachment_fetcher,
      webhook_destination_adapter: webhook_destination_adapter
    )
  end

  let(:submission) { create(:submission, submission_details: [submission_detail]) }

  let(:submission_detail) do
    {
      type: 'json',
      url: 'https://hmcts-complaints-formbuilder-adapter-staging.apps.live-1.cloud-platform.service.justice.gov.uk/v1/complaint',
      encryption_key: '19a56ee0e50dd83f',
      data_url: 'this-url-should-no-longer-be-called-or-used',
      submissionId: '5de849f3-bff4-4f10-b245-23b1435f1c70',
      user_answers: user_answers,
      attachments: []
    }
  end

  let(:user_answers) do
    {
      first_name: 'bob',
      last_name: 'madly',
      submissionDate: 1_571_756_381_535,
      submissionId: '5de849f3-bff4-4f10-b245-23b1435f1c70'
    }
  end

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
      submissionId: submission.submission_details[0][:submissionId],
      submissionAnswers: user_answers,
      attachments: attachments
    }.to_json
  end

  before do
    allow(webhook_destination_adapter).to receive(:send_webhook)
    allow(webhook_attachment_fetcher).to receive(:execute).and_return(attachments)
  end

  it 'modifies and sends the submission to the destination' do
    service.execute(submission: user_answers, service_slug: submission.service_slug)

    expect(webhook_destination_adapter).to have_received(:send_webhook)
      .with(body: json_payload)
      .once
  end

  it 'calls fetch_full_submission' do
    service.execute(submission: user_answers, service_slug: submission.service_slug)
  end

  it 'calls the webhook_attachment_fetcher' do
    service.execute(submission: user_answers, service_slug: submission.service_slug)
    expect(webhook_attachment_fetcher).to have_received(:execute).once
  end
end
