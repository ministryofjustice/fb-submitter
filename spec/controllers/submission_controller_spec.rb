require 'rails_helper'

RSpec.describe SubmissionController, type: :controller do
  let(:params) { { actions: 1, submission: { submission_id: 'abc', else: 1 }, attachments: [1, 2] } }

  before do
    request.env['CONTENT_TYPE'] = 'application/json'
    allow_any_instance_of(ApplicationController).to receive(:verify_token!)
  end

  it 'creates a submission' do
    post :create, body: params.to_json

    expect(Submission.all.count).to eq(1)
  end

  it 'saves the params into the submission' do
    post :create, body: params.to_json

    expect(Submission.first.payload).to eq(params.deep_stringify_keys)
  end

  it 'creates a delayed job' do
    post :create, body: params.to_json
    expect(Delayed::Job.all.count).to eq(1)
  end

  it 'marks delayed job as created' do
    post :create, body: params.to_json
    expect(response).to have_http_status(:created)
  end
end
