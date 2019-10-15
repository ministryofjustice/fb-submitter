# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

describe ProcessSubmissionService do
  subject do
    described_class.new(submission_id: submission.id)
  end

  let(:submission) do
    Submission.create!(
      encrypted_user_id_and_token: token,
      status: 'queued',
      submission_details: [],
      service_slug: 'service-slug'
    )
  end

  let(:mock_downloaded_files) { { 'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf' => '/path/to/file1', 'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid2.pdf' => '/path/to/file2' } }
  let(:downloaded_body_parts) { mock_downloaded_files }
  let(:body_part_content) do
    {
      'text/plain' => 'some plain text',
      'text/html' => '<html>some html</html>'
    }
  end
  let(:token) { 'some token' }
  let(:headers) { { 'x-encrypted-user-id-and-token' => token } }

  let(:attachments) do
    [
      {
        'type' => 'output',
        'mimetype' => 'application/pdf',
        'url' => '/api/submitter/pdf/default/guid1.pdf',
        'filename' => 'form1'
      },
      {
        'type' => 'output',
        'mimetype' => 'application/pdf',
        'url' => '/api/submitter/pdf/default/guid2.pdf',
        'filename' => 'form2'
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
        'body_parts' => {
          'text/html' => 'https://tools.ietf.org/html/rfc2324',
          'text/plain' => 'https://tools.ietf.org/rfc/rfc2324.txt'
        },
        'attachments' => attachments
      }
    end

    let(:pdf_submission) do
      {
        type: 'pdf',
        submission: {
          submission_id: '1786c427-246e-4bb7-90b9-a2e6cfae003f',
          pdf_heading: 'Best form on the web',
          pdf_subheading: '(Optional) Some section heading',
          sections: [
            {
              heading: 'Whats your name',
              summary_heading: 'WIP',
              questions: []
            }, {
              heading: '',
              summary_heading: '',
              questions: [
                {
                  label: 'First name',
                  answer: 'Bob'
                }, {
                  label: 'Last name',
                  answer: 'Smith'
                }
              ]
            }
          ]
        }
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

    let(:submission) do
      Submission.create!(
        encrypted_user_id_and_token: token,
        status: 'queued',
        submission_details: [submission_detail],
        service_slug: 'service-slug'
      )
    end

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
      allow(subject).to receive(:retrieve_mail_body_parts).and_return(body_part_content)
    end

    context 'with a mix of email, pdf and json submissions' do
      let(:runner_callback_url) { 'https://example.com/runner_frontend_callback' }
      let(:json_destination_url) { 'https://example.com/json_destination_placeholder' }

      let(:email_submission) do
        {
          'from' => 'some.one@example.com',
          'to' => 'destination@example.com',
          'subject' => 'mail subject',
          'type' => 'email',
          'body_parts' => {
            'text/html' => 'https://tools.ietf.org/html/rfc2324',
            'text/plain' => 'https://tools.ietf.org/rfc/rfc2324.txt'
          },
          'attachments' => attachments
        }
      end

      let(:json_submission) do
        {
          'type' => 'json',
          'url': json_destination_url,
          'data_url': runner_callback_url,
          'encryption_key': SecureRandom.hex(8),
          'attachments' => []
        }
      end

      let(:submission) do
        Submission.create!(
          submission_details: [
            email_submission,
            email_submission,
            json_submission,
            json_submission,
            json_submission,
            pdf_submission
          ], status: 'queued',
          service_slug: 'service-slug'
        )
      end

      let(:headers) do
        {
          'Expect' => '',
          'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus'
        }
      end

      let(:service_slug_secret) { SecureRandom.alphanumeric(10) }

      before do
        stub_request(:get, runner_callback_url).with(headers: headers).to_return(status: 200, body: '{"foo": "bar"}')
        stub_request(:post, json_destination_url).with(headers: headers).to_return(status: 200)
        stub_request(:post, 'http://pdf-generator.com/v1/pdfs')
          .with(body: pdf_submission.fetch(:submission).to_json, headers: headers).to_return(status: 200)

        stub_request(:get, 'http://fake_service_token_cache_root_url/service/service-slug').to_return(status: 200, body: { token: service_slug_secret }.to_json)
      end

      it 'dispatches 1 email for each submission email attachment' do
        expect(EmailService).to receive(:send_mail).exactly(5).times
        subject.perform
      end

      it 'dispatches json submissions to the webhook class' do
        subject.perform
        expect(WebMock).to have_requested(:get, runner_callback_url).times(3)
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

      describe 'for each detail object' do
        let(:email_details) { submission.submission_details.first.with_indifferent_access }

        it 'asks the EmailService to send an email' do
          allow(subject).to receive(:attachments).and_return(processed_attachments)

          expect(EmailService).to receive(:send_mail).with(
            from: email_details.fetch(:from),
            to: email_details.fetch(:to),
            subject: email_details.fetch(:subject),
            body_parts: body_part_content,
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
          'body_parts' => {
            'text/html' => 'https://tools.ietf.org/html/rfc2324',
            'text/plain' => 'https://tools.ietf.org/rfc/rfc2324.txt'
          },
          'attachments' => []
        }
      end

      it 'sends one email' do
        expect(EmailService).to receive(:send_mail).once

        subject.perform
      end
    end

    context 'when there is 1 attachment' do
      let(:submission_detail) do
        {
          'from' => 'some.one@example.com',
          'to' => 'destination@example.com',
          'subject' => 'mail subject',
          'type' => 'email',
          'body_parts' => {
            'text/html' => 'https://tools.ietf.org/html/rfc2324',
            'text/plain' => 'https://tools.ietf.org/rfc/rfc2324.txt'
          },
          'attachments' => [
            {
              'type' => 'output',
              'mimetype' => 'application/pdf',
              'url' => '/api/submitter/pdf/default/guid1.pdf',
              'filename' => 'form1'
            }
          ]
        }
      end

      it 'sends one email' do
        expect(EmailService).to receive(:send_mail).once

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
          'body_parts' => {
            'text/html' => 'https://tools.ietf.org/html/rfc2324',
            'text/plain' => 'https://tools.ietf.org/rfc/rfc2324.txt'
          },
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
        Submission.create!(submission_details: [submission_detail_1, submission_detail_2],
                           status: 'queued', service_slug: 'test-service-slug')
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

  describe '#retrieve_mail_body_parts' do
    let(:mail) { instance_double(EmailSubmissionDetail) }

    before do
      allow(subject).to receive(:download_body_parts).with(mail).and_return(mock_downloaded_files)
      allow(subject).to receive(:read_downloaded_body_parts).with(mail, mock_downloaded_files).and_return(body_part_content)
    end

    it 'downloads the body parts' do
      expect(subject).to receive(:download_body_parts).with(mail).and_return(mock_downloaded_files)
      subject.send(:retrieve_mail_body_parts, mail)
    end

    it 'reads the downloaded body parts' do
      expect(subject).to receive(:read_downloaded_body_parts).with(mail, mock_downloaded_files).and_return(body_part_content)
      subject.send(:retrieve_mail_body_parts, mail)
    end

    it 'returns the map of content type to content' do
      expect(subject.send(:retrieve_mail_body_parts, mail)).to eq(body_part_content)
    end
  end

  describe '#download_body_parts' do
    let(:mail) { instance_double(EmailSubmissionDetail) }

    before do
      allow(mail).to receive(:body_parts).and_return('text/plain' => 'url1', 'text/html' => 'url2')
      allow(DownloadService).to receive(:download_in_parallel).with(
        urls: %w[url1 url2],
        headers: headers
      ).and_return('download result')
    end

    it 'asks the DownloadService to download the resolved body part urls in parallel' do
      expect(DownloadService).to receive(:download_in_parallel).with(
        urls: %w[url1 url2],
        headers: headers
      )
      subject.send(:download_body_parts, mail)
    end

    it 'returns the result of the download call' do
      expect(subject.send(:download_body_parts, mail)).to eq('download result')
    end
  end

  describe '#read_downloaded_body_parts' do
    context 'when a mail with body parts' do
      let(:mail) { instance_double(EmailSubmissionDetail) }

      before do
        allow(mail).to receive(:body_parts).and_return('text/plain' => 'url1', 'text/html' => 'url2')
      end

      context 'with a map of urls to file paths' do
        let(:file_map) { { 'url1' => 'file1', 'url2' => 'file2' } }
        let(:mock_file_1) { instance_double(File) }
        let(:mock_file_2) { instance_double(File) }

        before do
          allow(mock_file_1).to receive(:read).and_return('file 1 content')
          allow(mock_file_2).to receive(:read).and_return('file 2 content')

          allow(File).to receive(:open).with('file1').and_yield(mock_file_1)
          allow(File).to receive(:open).with('file2').and_yield(mock_file_2)
        end

        it 'reads each file' do
          expect(File).to receive(:open).with('file1').and_yield(mock_file_1)
          expect(File).to receive(:open).with('file2').and_yield(mock_file_2)
          subject.send(:read_downloaded_body_parts, mail, file_map)
        end

        it 'returns a map of content types to file content' do
          expect(subject.send(:read_downloaded_body_parts, mail, file_map)).to eq(
            'text/plain' => 'file 1 content', 'text/html' => 'file 2 content'
          )
        end
      end
    end
  end

  describe '#perform' do
    context 'with filestore attachments' do
      let(:submission) do
        Submission.new(
          encrypted_user_id_and_token: 'encrypted_user_id_and_token',
          status: 'queued',
          submission_details: [submission_detail],
          service_slug: 'service-slug'
        )
      end

      let(:submission_detail) do
        {
          'from' => 'some.one@example.com',
          'to' => 'destination@example.com',
          'subject' => 'mail subject',
          'type' => 'email',
          'body_parts' => {
            'text/html' => 'https://tools.ietf.org/html/rfc2324',
            'text/plain' => 'https://tools.ietf.org/rfc/rfc2324.txt'
          },
          'attachments' => [
            {
              'type' => 'output',
              'mimetype' => 'application/pdf',
              'url' => '/api/submitter/pdf/default/guid1.pdf',
              'filename' => 'form1'
            },
            {
              'type' => 'filestore',
              'mimetype' => 'image/png',
              'url' => 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev//service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8',
              'filename' => 'image2.png'
            }
          ]
        }
      end

      before do
        allow(Submission).to receive(:find).and_return(submission)
        allow(submission).to receive(:id).and_return('id-of-submission')
      end
    end
  end
end
