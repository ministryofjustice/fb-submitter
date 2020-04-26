require 'rails_helper'

RSpec.describe SubmissionController, type: :controller do
  let(:payload) do
    {
      meta: {
        submission_id: '123',
        submission_at: '2019-12-18T13:19:29.626Z'
      },
      actions: 1,
      submission: {
        submission_id: '123',
        else: 1
      },
      attachments: [1, 2]
    }
  end

  let(:headers) do
    {
      'content-type' => 'application/json',
      'x-access-token-v2' => token
    }
  end

  let(:token) { 'some-access-token' }

  before do
    request.headers.merge!(headers)
    allow_any_instance_of(ApplicationController).to receive(:verify_token!)
    post :create, body: payload.to_json, format: :json
  end

  it 'creates a submission' do
    expect(Submission.all.count).to eq(1)
  end

  it 'persists access token' do
    expect(Submission.first.access_token).to eq(token)
  end

  it 'saves the payload into the submission' do
    expect(Submission.first.decrypted_payload).to eq(payload.deep_stringify_keys)
  end

  it 'returns valid json response' do
    expect { JSON.parse(response.body) }.not_to raise_error
  end
end
