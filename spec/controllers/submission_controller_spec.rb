require 'rails_helper'

RSpec.describe SubmissionController, type: :controller do
  before do
    request.env['CONTENT_TYPE'] = 'application/json'
    allow_any_instance_of(ApplicationController).to receive(:verify_token!)
  end

  it 'creates a submission' do
    post :create, body: { something: 1 }.to_json

    expect(Submission.all.count).to eq(1)
  end

  it 'starts a delayed job' do
    post :create, body: { something: 1 }.to_json

    expect(response).to have_http_status(:created)
    expect(Delayed::Job.all.count).to eq(1)
  end
end
