require 'rails_helper'
require 'webmock/rspec'
require 'jwe'

describe 'Submits JSON given a JSON submission type', type: :request do
  let(:service_slug) { 'my-service' }
  let(:user_identifier) { SecureRandom.uuid }
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
    }
  end
  let(:encryption_key) { "fb730a667840d79c" }
  let(:encrypted_submission) { JWE.encrypt(submission_answers.to_json, encryption_key, alg: 'dir') }

  describe 'POST /submission' do
    before do
      Delayed::Worker.delay_jobs = false
      allow_any_instance_of(ApplicationController).to receive(:verify_token!)

      stub_request(:get, "https://formbuilder.com/runner_frontend_callback")
         .to_return(status: 200, body: submission_answers.to_json)
    end

    after do
       Delayed::Worker.delay_jobs = true
    end

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
    let!(:json_payload_submission) do
      stub_request(:post, json_destination_url)
         .with(body: encrypted_submission.to_json)
         .to_return(status: 200, body: "", headers: {})
    end

    it 'sends JSON to the external endpoint' do
      post '/submission', params: params, headers: headers
      expect(json_payload_submission).to have_been_requested
    end
  end
end
