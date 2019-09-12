require 'rails_helper'
require 'webmock/rspec'
require 'jwe'

module LastRequest
  def last_request
    @last_request
  end

  def last_request=(request_signature)
    @last_request = request_signature
  end
end

WebMock.extend(LastRequest)
WebMock.after_request do |request_signature, response|
  WebMock.last_request = request_signature
end

describe 'Submits JSON given a JSON submission type', type: :request do
  let(:service_slug) { 'my-service' }
  let(:submission_id) { '1e937616-dd0b-4bc3-8c67-40e4ffd54f78' }
  let(:submission_answers) do
    {
      "full_name": "Mr Complainer",
      "email_address": "test@test.com",
      "building_street": "102 Petty France",
      "building_street_line_2": "Westminster",
      "town_city": "London",
      "county": "London",
      "postcode": "SW1H 9AJ",
      "complaint_details": "I lost my case",
      "complaint_location": "Westminster Magistrates'",
      "submissionId": submission_id,
      "submissionDate": "1568199892316"
    }
  end
  let(:expected_json_payload) do
    {
      "serviceSlug": service_slug,
      "submissionId": submission_id,
      "submissionAnswers": submission_answers.except(:submissionId)
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

  before do
    Delayed::Worker.delay_jobs = false
    allow_any_instance_of(ApplicationController).to receive(:verify_token!)

    stub_request(:get, "https://formbuilder.com/runner_frontend_callback")
       .to_return(status: 200, body: submission_answers.to_json)

    stub_request(:post, json_destination_url).to_return(status: 200, body: "")
  end

  after do
    Delayed::Worker.delay_jobs = true
  end

  it 'sends the correct JSON to the external endpoint' do
    post '/submission', params: params, headers: headers
    json_submission_payload = JWE.decrypt(WebMock.last_request.body, encryption_key)
    expect(json_submission_payload).to eq(expected_json_payload)
  end
end
