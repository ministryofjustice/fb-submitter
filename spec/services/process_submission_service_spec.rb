# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

describe ProcessSubmissionService do
  subject do
    described_class.new(id: submission.id)
  end

  let(:submission) do
    create(:submission, :json, submission: submission_answers)
  end

  let(:submission_answers) do
    {
      'submission_id' => '8f5dd756-df07-40e7-afc7-682cdf490264',
      'pdf_heading' => 'Complain about a court or tribunal',
      'sections' => []
    }
  end

  let(:mock_downloaded_files) do
    {
      'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8' => '/path/to/file1',
      'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dwdwdw' => '/path/to/file2'
    }
  end

  let(:token) { 'some token' }
  let(:headers) { { 'x-encrypted-user-id-and-token' => token } }

  let(:attachments) do
    [
      {
        type: 'filestore',
        mimetype: 'image/png',
        url: 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8',
        filename: 'doge'
      }, {
        type: 'filestore',
        mimetype: 'image/png',
        url: 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dwdwdw',
        filename: 'doge1'
      }
    ]
  end

  describe '#perform' do
    let(:submission_detail) do
      {
        'from' => 'some.one@example.com',
        'to' => 'destination@example.com',
        'subject' => 'mail subject',
        'type' => 'email',
        'attachments' => attachments
      }
    end

    let(:processed_attachments) do
      [
        Attachment.new(
          path: '/path/to/file1',
          type: 'output',
          mimetype: 'application/pdf',
          url: 'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf',
          filename: 'form1'
        )
      ]
    end

    let(:submission) { create(:submission, :email) }

    let(:detail_objects) do
      [EmailSubmissionDetail.new(submission_detail)]
    end

    let(:urls) do
      ['http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf', 'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid2.pdf']
    end

    let(:mock_send_response) { { 'key' => 'send response' } }

    before do
      allow(EmailService).to receive(:send_mail).and_return(mock_send_response)
      allow(DownloadService).to receive(:download_in_parallel).and_return(
        mock_downloaded_files
      )
    end

    context 'with a mix of email, pdf and json submissions' do
      let(:json_destination_url) { 'https://example.com/json_destination_placeholder' }

      let(:email_submission) do
        {
          'type' => 'email',
          'from' => 'some.one@example.com',
          'to' => 'destination@example.com',
          'subject' => 'mail subject',
          'email_body' => 'some plain text',
          'attachments' => attachments
        }
      end

      let(:json_submission) do
        {
          'type' => 'json',
          'url': json_destination_url,
          'data_url': 'deprecated field',
          'encryption_key': SecureRandom.hex(8),
          user_answers: user_answers,
          'attachments' => []
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

      let(:submission) do
        create(:submission,
               submission_details: [
                 email_submission,
                 email_submission
               ],
               submission: submission_answers,
               actions: [
                 json_submission,
                 json_submission,
                 json_submission
               ],
               attachments: attachments)
      end

      let(:headers) do
        {
          'Expect' => '',
          'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus'
        }
      end

      let(:service_slug_secret) { SecureRandom.alphanumeric(10) }

      let(:presigned_url_response) do
        {
          url: 'example.com/public_url_1',
          encryption_key: 'somekey_1',
          encryption_iv: 'somekey_iv_1'
        }.to_json
      end

      let(:presigned_url_response_2) do
        {
          url: 'example.com/public_url_2',
          encryption_key: 'somekey_1',
          encryption_iv: 'somekey_iv_1'
        }.to_json
      end

      before do
        stub_request(:post, json_destination_url).with(headers: headers).to_return(status: 200)
        stub_request(:post, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8/presigned-s3-url')
          .to_return(status: 200, body: presigned_url_response)
        stub_request(:post, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dwdwdw/presigned-s3-url')
          .to_return(status: 200, body: presigned_url_response_2)
      end

      it 'downloads attachments' do
        subject.perform
        # TODO: each attachment should only be downloaded once
        expect(WebMock).to have_requested(:post, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8/presigned-s3-url').times(3)
        expect(WebMock).to have_requested(:post, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dwdwdw/presigned-s3-url').times(3)
      end

      it 'dispatches 1 email for each submission email attachment' do
        expect(EmailService).to receive(:send_mail).exactly(4).times
        subject.perform
      end

      it 'dispatches json submissions to the webhook class' do
        subject.perform
        expect(WebMock).to have_requested(:post, json_destination_url).times(3)
      end
    end

    context 'with a valid submission_id' do
      let(:submission_id) { submission.id }

      before do
        allow(Submission).to receive(:find).with(submission_id).and_return(submission)
      end

      it 'calls Submission find ' do
        expect(Submission).to receive(:find).with(submission_id).once
        subject.perform
      end

      it 'updates the Submission status to :processing' do
        expect(submission).to receive(:update_status).with(:processing)
        subject.perform
      end

      it 'gets the unique_attachment_urls' do
        expect(subject).to receive(:unique_attachment_urls).and_return(urls)
        subject.perform
      end

      it 'downloads the resolved unique_attachment_urls in parallel' do
        expect(DownloadService).to receive(:download_in_parallel)
          .with(urls: urls, headers: headers)
          .and_return(mock_downloaded_files)
        subject.perform
      end

      it 'gets the detail_objects from the Submission' do
        expect(submission).to receive(:detail_objects).at_least(:once).and_call_original
        subject.perform
      end

      describe 'for each detail object' do
        let(:detail_object) { submission.detail_objects.first }

        it 'asks the EmailService to send an email' do
          allow(subject).to receive(:attachments).and_return(processed_attachments)

          expect(EmailService).to receive(:send_mail).with(
            from: detail_object.from,
            to: detail_object.to,
            subject: detail_object.subject,
            body_parts: {
              'text/plain' => 'some plain text'
            },
            attachments: processed_attachments
          ).and_return(mock_send_response)
          subject.perform
        end

        it 'adds the response to the submission responses' do
          subject.perform
          expect(submission.responses).to eq([mock_send_response, mock_send_response])
        end

        it 'saves the submission' do
          expect(submission).to receive(:save!)
          subject.perform
        end

        it 'completes the submission' do
          subject.perform
          expect(submission.status).to eq('completed')
        end
      end
    end

    context 'when there are no attachments' do
      let(:submission_detail) do
        {
          'from' => 'some.one@example.com',
          'to' => 'destination@example.com',
          'subject' => 'mail subject',
          'type' => 'email',
          'email_body' => 'some plain text',
          'attachments' => []
        }
      end

      let(:submission) do
        create(:submission,
               submission_details: [submission_detail],
               submission: submission_answers)
      end

      it 'sends one email' do
        expect(EmailService).to receive(:send_mail).once

        subject.perform
      end
    end

    context 'when there are 2 attachments' do
      it 'sends two emails' do
        expect(EmailService).to receive(:send_mail).twice

        subject.perform
      end
    end

    context 'when there are more then 1 attachments' do
      let(:submission_detail) do
        {
          'from' => 'some.one@example.com',
          'to' => 'destination@example.com',
          'subject' => 'mail subject',
          'type' => 'email',
          'email_body' => 'some plain text',
          'attachments' => attachments
        }
      end

      it 'sends multiple emails' do
        expect(EmailService).to receive(:send_mail).twice

        subject.perform
      end
    end
  end

  describe '#unique_attachment_urls' do
    context 'with a submission with multiple detail objects, each with attachments' do
      let(:submission_detail_1) do
        {
          'type' => 'email',
          'email_body' => 'some plain text',
          'attachments' => [
            {
              type: 'output',
              mimetype: 'application/pdf',
              url: '/api/submitter/pdf/default/guid1.pdf',
              filename: 'form1'
            },
            {
              type: 'output',
              mimetype: 'application/pdf',
              url: '/api/submitter/pdf/default/guid2.pdf',
              filename: 'form2'
            }
          ]
        }
      end
      let(:submission_detail_2) do
        {
          'type' => 'email',
          'email_body' => 'some plain text',
          'attachments' => [
            {
              type: 'output',
              mimetype: 'application/pdf',
              url: '/api/submitter/pdf/default/guid2.pdf',
              filename: 'form2'
            },
            {
              type: 'output',
              mimetype: 'application/pdf',
              url: '/api/submitter/pdf/default/guid3.pdf',
              filename: 'form3'
            }
          ]
        }
      end

      let(:submission) do
        create(:submission, submission_details: [submission_detail_1, submission_detail_2], submission: submission_answers, service_slug: 'test-service-slug')
      end

      it 'returns a single array of unique urls' do
        expect(subject.send(:unique_attachment_urls)).to eq(
          ['http://test-service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf',
           'http://test-service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid2.pdf',
           'http://test-service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid3.pdf']
        )
      end
    end
  end

  context 'with unknown type' do
    let(:submission) do
      create(:submission,
             actions: [
               { 'type' => 'what is this type?' }
             ])
    end

    it 'ignores it' do
      subject.perform
    end
  end

  context 'with PDF payload' do
    before do
      create(:submission,
             submission: submission_answers,
             encrypted_user_id_and_token: 'encrypted_user_id_and_token',
             submission_details: [
               {
                 'from' => 'some.one@example.com',
                 'to' => 'destination@example.com',
                 'subject' => 'mail subject',
                 'type' => 'email',
                 'email_body' => 'some plain text',
                 'attachments' => [
                   {
                     'type' => 'output',
                     'mimetype' => 'application/pdf',
                     'url' => '/api/submitter/pdf/default/guid1.pdf',
                     'filename' => 'form1',
                     'pdf_data' => {
                       'some_pdf' => 'data'
                     }
                   }
                 ]
               }
             ])

      stub_request(:get, 'http://fake_service_token_cache_root_url/service/service-slug').to_return(status: 200, body: { token: '123' }.to_json)
      stub_request(:post, 'http://pdf-generator.com/v1/pdfs').with(body: '{"some_pdf":"data"}')

      allow(EmailService).to receive(:send_mail).and_return(some: 'mock response')
    end

    let(:submission) { Submission.last }

    it 'sends an email with the newly generated pdf contents' do
      expect(EmailService).to receive(:send_mail)
      subject.perform
    end
  end
end
