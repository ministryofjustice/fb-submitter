require 'rails_helper'

describe JsonWebhookService do
  let(:submission) { create(:submission) }
  let(:runner_callback_adapter) do
    instance_double(Adapters::RunnerCallback)
  end
  let(:webhook_destination_adapter) do
    instance_double(Adapters::WebhookDestination)
  end

  subject do
    described_class.new(
      service_slug: submission.service_slug,
      runner_callback_adapter: runner_callback_adapter,
      webhook_destination_adapter: webhook_destination_adapter
    )
  end

  let(:frontend_response) { submission.submission_details.to_json }
  let(:json_payload) do
    {
      serviceSlug: submission.service_slug,
      submissionId: submission.submission_details['submissionId'],
      submissionAnswers: submission.submission_details.except('submissionId')
    }.to_json
  end

  before do
    expect(runner_callback_adapter).to receive(:fetch_full_submission).and_return(frontend_response)
  end

  it 'gets full submission from the frontend service' do
    allow(webhook_destination_adapter).to receive(:send_webhook)

    subject.execute
  end

  it 'modifies and sends the submission to the destination' do
    expect(webhook_destination_adapter).to receive(:send_webhook)
      .with(body: json_payload)
      .once

    subject.execute
  end
end
