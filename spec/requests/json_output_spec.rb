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
WebMock.after_request do |request_signature, _response|
  WebMock.last_request = request_signature
end

describe 'Submits JSON given a JSON submission type', type: :request do
  let(:service_slug) { 'my-service' }
  let(:submission_id) { '1e937616-dd0b-4bc3-8c67-40e4ffd54f78' }

  let(:expected_submission_answers) do
    {
      'first_name' => 'Bob',
      'last_name' => 'Smith',
      'has-email' => 'Yes',
      'email_address' => 'bob.smith@digital.justice.gov.uk',
      'complaint_details' => 'Some complaint details',
      'has-complaint-documents' => 'No'
    }
  end

  let(:submission) do
    {
      'submission_id' => submission_id,
      'pdf_heading' => 'Complain about a court or tribunal',
      'sections' =>
        [
          { 'heading' => 'Your name', 'summary_heading' => '', 'questions' => [] },
          { 'heading' => '',
            'summary_heading' => '',
            'questions' =>
              [
                { 'label' => 'First name', 'answer' => 'Bob', 'key' => 'first_name' },
                { 'label' => 'Last name', 'answer' => 'Smith', 'key' => 'last_name' }
              ] },
          { 'heading' => '',
            'summary_heading' => '',
            'questions' =>
              [{ 'label' => 'Can we contact you about your complaint by email?',
                 'answer' => 'Yes',
                 'key' => 'has-email' },
               { 'label' => 'Your email address',
                 'answer' => 'bob.smith@digital.justice.gov.uk',
                 'key' => 'email_address' },
               { 'label' => 'Your complaint',
                 'answer' => 'Some complaint details',
                 'key' => 'complaint_details' },
               { 'label' =>
                   'Would you like to send any documents as part of your complaint?',
                 'answer' => 'No',
                 'key' => 'has-complaint-documents' }] }
        ]
    }
  end

  let(:expected_attachments) do
    [
      {
        url: 'example.com/1',
        encryption_key: 'bar1',
        encryption_iv: 'baz1',
        mimetype: 'application/pdf',
        filename: 'form1.pdf'
      },
      {
        url: 'example.com/2',
        encryption_key: 'bar2',
        encryption_iv: 'baz2',
        mimetype: 'application/pdf',
        filename: 'form2.pdf'
      }
    ]
  end

  let(:expected_json_payload) do
    {
      "serviceSlug": service_slug,
      "submissionId": submission_id,
      "submissionAnswers": expected_submission_answers,
      attachments: expected_attachments
    }.to_json
  end

  let(:json_destination_url) { 'https://example.com/json_destination_placeholder' }
  let(:attachment_url) { 'https://some-url/1' }

  let(:encryption_key) { 'fb730a667840d79c' }
  let(:encrypted_user_id_and_token) { 'kdjh9s8db9s87dbosd7b0sd8b70s9d8bs98d7b9s8db' }
  let(:actions) do
    [
      {
        'type' => 'json',
        'url': json_destination_url,
        'data_url': 'deprecated field',
        'encryption_key': encryption_key
      }
    ]
  end

  let(:attachments) do
    [
      {
        'type' => 'output',
        'mimetype' => 'application/pdf',
        'url' => 'https://some-url/1',
        'filename' => 'form1'
      },
      {
        'type' => 'output',
        'mimetype' => 'application/pdf',
        'url' => 'https://some-url/2',
        'filename' => 'form2'
      }
    ]
  end

  let(:headers) { { 'Content-type' => 'application/json' } }
  let(:params) do
    {
      service_slug: service_slug,
      encrypted_user_id_and_token: encrypted_user_id_and_token,
      attachments: attachments,
      actions: actions,
      submission: submission
    }.to_json
  end

  before do
    Delayed::Worker.delay_jobs = false
    allow_any_instance_of(ApplicationController).to receive(:verify_token!)

    stub_request(:post, json_destination_url).to_return(status: 200, body: '')

    stub_request(:post, 'https://some-url/1/presigned-s3-url').to_return(status: 200, body: expected_attachments[0].to_json)
    stub_request(:post, 'https://some-url/2/presigned-s3-url').to_return(status: 200, body: expected_attachments[1].to_json)
    allow_any_instance_of(ApplicationController).to receive(:enforce_json_only).and_return(true)
  end

  after do
    Delayed::Worker.delay_jobs = true
  end

  it 'calls the user file store to get a public signed url' do
    post '/submission', params: params, headers: headers
    expect(WebMock).to have_requested(:post, "#{attachment_url}/presigned-s3-url").once
  end

  it 'sends the correct JSON to the external endpoint' do
    post '/submission', params: params, headers: headers
    json_submission_payload = JWE.decrypt(WebMock.last_request.body, encryption_key)
    expect(json_submission_payload).to eq(expected_json_payload)
  end
end
