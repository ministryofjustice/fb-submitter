# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

describe ProcessSubmissionService do
  subject(:service) { ProcessSubmissionService.new(id: submission.id) }

  before do
    # Stub service token cache API call
    stub_request(:get, "http://fake_service_token_cache_root_url/service/service-slug")
      .to_return(status: 200, body: {token: "123"}.to_json, headers: {})
  end

  context 'when sending an email submission' do
    let(:actions) do
      [
        {
          'recipientType' => 'team',
          'type' => 'email',
          'from' =>
          '"Complain about a court or tribunal" <form-builder@digital.justice.gov.uk>',
          'to' => 'bob.admin@digital.justice.gov.uk',
          'subject' => 'Complain about a court or tribunal submission',
          'email_body' => 'Please find an application attached',
          'include_pdf' => true,
          'include_attachments' => true
        }
      ]
    end
    let(:attachments) do
      [
        {
          "url"=>"http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev//service/phil-ioj/user/1/123",
          "mimetype"=>"image/jpeg",
          "filename"=>"an-image.jpg",
          "type"=>"filestore"
        }
      ]
    end
    let(:submission_service_spy) { instance_spy(EmailOutputService) }
    let(:mock_pdf_contents) { "hello world\n" }

    before do
      # Stub PDF API call
      stub_request(:post, "http://pdf-generator.com/v1/pdfs")
        .to_return(status: 200, body: "hello world\n", headers: {})
      # Stub filestore API call
      stub_request(:get, "http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev//service/phil-ioj/user/1/123")
        .to_return(status: 200, body: "image", headers: {})
      allow(EmailOutputService).to receive(:new).and_return(submission_service_spy)
    end

    context 'with one attachment' do
      let(:submission) { create(:submission, :email, actions: actions, attachments: attachments) }
      before do
        service.perform
      end

      it 'passes the PDF of answers to the EmailOutputService' do
        expect(submission_service_spy).to have_received(:execute) do |args|
          pdf_contents = File.open(args[:pdf_attachment].path).read
          expect(pdf_contents).to eq(mock_pdf_contents)
        end
      end

      it 'passes the correct attachments to the EmailOutputService' do
        expect(submission_service_spy).to have_received(:execute) do |args|
          expect(args[:attachments].length).to eq(attachments.length)
          attachment = args[:attachments].first
          expect(attachment.filename).to eq(attachments.first['filename'])
        end
      end

      it 'passes the correct submission_id to the EmailOutputService' do
        expect(submission_service_spy).to have_received(:execute) do |args|
          expect(args[:submission_id]).to eq(submission.payload['submission']['submission_id'])
        end
      end

      it 'passes the correct action to the EmailOutputService' do
        expect(submission_service_spy).to have_received(:execute) do |args|
          expect(args[:action]).to eq(actions.first)
        end
      end
    end

    context 'with multiple attachments' do
      let(:attachments) do
        [
          {
            "url"=>"http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev//service/phil-ioj/user/1/123",
            "mimetype"=>"image/jpeg",
            "filename"=>"an-image.jpg",
            "type"=>"filestore"
          },
          {
            "url"=>"http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev//service/phil-ioj/user/1/123",
            "mimetype"=>"image/jpeg",
            "filename"=>"a-second-image.jpg",
            "type"=>"filestore"
          }
        ]
      end
      let(:submission) { create(:submission, :email, actions: actions, attachments: attachments) }
      before do
        service.perform
      end

      it 'downloads and passes through all attachments' do
        expect(submission_service_spy).to have_received(:execute) do |args|
          expect(args[:attachments].length).to eq(attachments.length)
          first_attachment = args[:attachments].first
          expect(first_attachment.filename).to eq(attachments.first['filename'])
          second_attachment = args[:attachments].second
          expect(second_attachment.filename).to eq(attachments.second['filename'])
        end
      end
    end
  end

  context 'when sending a JSON submission' do
    let(:json_destination_url) { 'https://example.com/json_destination_placeholder' }
    let(:encryption_key) { 'fb730a667840d79c' }
    let(:actions) do
      [
        {
          'type' => 'json',
          'url' => json_destination_url,
          'data_url' => 'deprecated field',
          'encryption_key' => encryption_key
        }
      ]
    end
    let(:submission) { create(:submission, actions: actions) }
    let(:json_webhook_service_spy) { instance_spy(JsonWebhookService) }

    before do
      allow(JsonWebhookService).to receive(:new).and_return(json_webhook_service_spy)
      service.perform
    end

    it 'passes the correct collaborators to the JsonWebhookService' do
      expect(JsonWebhookService).to have_received(:new) do |args|
        expect(args[:webhook_attachment_fetcher]).to be_an_instance_of(WebhookAttachmentService)
        expect(args[:webhook_destination_adapter]).to be_an_instance_of(Adapters::JweWebhookDestination)
      end
    end

    it 'passes the correct user_answers payload as an argument' do
      user_answers = SubmissionPayloadService.new(submission.payload).user_answers_map

      expect(json_webhook_service_spy).to have_received(:execute) do |args|
        expect(args[:user_answers]).to eq(user_answers)
      end
    end

    it 'passes the correct submission_id as an argument' do
      expect(json_webhook_service_spy).to have_received(:execute) do |args|
        expect(args[:submission_id]).to eq(submission.payload['submission']['submission_id'])
      end
    end

    it 'passes the correct service_slug as an argument' do
      expect(json_webhook_service_spy).to have_received(:execute) do |args|
        expect(args[:service_slug]).to eq(submission.service_slug)
      end
    end
  end

  context 'when the action type is neither email nor JSON' do
    let(:actions) do
      [
        {
          'type' => 'unknown'
        }
      ]
    end
    let(:submission) { create(:submission, actions: actions) }

    it 'logs a warning' do
      expect(Rails.logger).to receive(:warn).with("Unknown action type 'unknown' for submission id #{submission.id}")
      service.perform
    end
  end
end
