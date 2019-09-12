require 'rails_helper'
require 'webmock/rspec'

describe 'Submitting a form with JSON output turned on', type: :request do
  class JweWebhookDestinationSpy
    def send_webhook(body:)
      @body = body
      true
    end

    attr_reader :body
  end

  let(:service_slug) { 'my-service' }
  let(:submission_answers) do
    {
      "full_name": "Tom Taylor",
      "email_address": "tommotaylor@gmail.com",
      "building_street": "9a St Marks Rise",
      "building_street_line_2": "Dalston",
      "town_city": "London",
      "county": "London",
      "postcode": "E8 2NJ",
      "case_number": "case_number_yes",
      "case_number_details": "12345",
      "complaint_details": "I lost my case",
      "complaint_location": "Westminster Magistrates'",
      "complaint_evidence": "complaint_evidence_no",
      "submissionId": "1e937616-dd0b-4bc3-8c67-40e4ffd54f78",
      "submissionDate": "1568199892316"
    }.to_json
  end
  let(:encryption_key) { "fb730a667840d79c" }
  let(:runner_callback_url) { 'https://formbuilder.com/runner_frontend_callback' }
  let(:json_destination_url) { 'https://example.com/json_destination_placeholder' }
  let(:encrypted_user_id_and_token) { 'kdjh9s8db9s87dbosd7b0sd8b70s9d8bs98d7b9s8db' }
  let(:submission_details) do
    [
      {
        'type' => 'json',
        'url': json_destination_url,
        'data_url': runner_callback_url,
        'encryption_key': encryption_key,
        'attachments' => []
      }
    ]
  end
  let(:headers) { { 'Content-type' => 'application/json' } }
  let(:params) do
    {
      service_slug: service_slug,
      encrypted_user_id_and_token: encrypted_user_id_and_token,
      submission_details: submission_details
    }.to_json
  end
  let(:jwe_webhook_destination_spy) { JweWebhookDestinationSpy.new }

  before do
    Delayed::Worker.delay_jobs = false
    allow_any_instance_of(ApplicationController).to receive(:verify_token!)
    allow(Adapters::JweWebhookDestination).to receive(:new).and_return(jwe_webhook_destination_spy)
    stub_request(:get, "https://formbuilder.com/runner_frontend_callback")
       .to_return(status: 200, body: submission_answers)
  end

  after do
     Delayed::Worker.delay_jobs = true
  end

  it 'sends correct JSON payload to the external endpoint' do
    post '/submission', params: params, headers: headers
    json_output_payload = jwe_webhook_destination_spy.body
    expect(json_output_payload).to eq(submission_answers)
  end
end
