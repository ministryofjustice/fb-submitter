# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

describe ProcessSubmissionService do
  let(:submission) do
    Submission.create!(
      encrypted_user_id_and_token: token,
      status: 'queued',
      submission_details: [],
      service_slug: 'service-slug'
    )
  end

  subject do
    described_class.new(submission_id: submission.id)
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

    context 'given a mix of email and json submissions' do
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
            json_submission
          ], status: 'queued'
        )
      end

      let(:headers) do
        {
          'Expect' => '',
          'User-Agent' => 'Typhoeus - https://github.com/typhoeus/typhoeus'
        }
      end

      before do
        stub_request(:get, runner_callback_url).with(headers: headers).to_return(status: 200, body: '{"foo": "bar"}')
        stub_request(:post, json_destination_url).with(headers: headers).to_return(status: 200)
      end

      it 'dispatches 1 email for each submission email attachment' do
        expect(EmailService).to receive(:send_mail).exactly(4).times
        subject.perform
      end

      it 'dispatches json submissions to the webhook class' do
        subject.perform
        expect(WebMock).to have_requested(:get, runner_callback_url).times(3)
        expect(WebMock).to have_requested(:post, json_destination_url).times(3)
      end
    end

    context 'given a valid submission_id' do
      let(:submission_id) { submission.id }

      before do
        expect(Submission).to receive(:find).with(submission_id).and_return(submission)
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
    context 'given a submission with multiple detail objects, each with attachments' do
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
                           status: 'queued')
      end

      it 'returns a single array of unique urls' do
        expect(subject.send(:unique_attachment_urls)).to eq(
          ['http://.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf',
           'http://.formbuilder-services-test:3000/api/submitter/pdf/default/guid2.pdf',
           'http://.formbuilder-services-test:3000/api/submitter/pdf/default/guid3.pdf']
        )
      end
    end
  end

  describe '#retrieve_mail_body_parts' do
    let(:mail) { double('mail') }
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
    let(:mail) { double('mail', body_parts: { 'text/plain' => 'url1', 'text/html' => 'url2' }) }
    before do
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
    context 'given a mail with body parts' do
      let(:mail) { double('mail', body_parts: { 'text/plain' => 'url1', 'text/html' => 'url2' }) }

      context 'and a map of urls to file paths' do
        let(:file_map) { { 'url1' => 'file1', 'url2' => 'file2' } }
        let(:mock_file_1) { double('File1', read: 'file 1 content') }
        let(:mock_file_2) { double('File2', read: 'file 2 content') }
        before do
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

      before :each do
        allow(Submission).to receive(:find).and_return(submission)
        allow(submission).to receive(:id).and_return('id-of-submission')
      end

      it 'converts output urls to absolute urls' do
        url = submission.detail_objects.dig(0).attachments.dig(0, 'url')
        expect(url).to start_with('http')
      end

      it 'attaches filestore attachments' do
        expect(DownloadService).to receive(:download_in_parallel)
          .with(headers: {
                  'x-encrypted-user-id-and-token' => 'encrypted_user_id_and_token'
                }, urls: [
                  'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev//service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8',
                  'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf'
                ]).and_return(
                  'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev//service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8' => '/tmp/filestore.png',
                  'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf' => '/tmp/output.pdf'
                )

        # only testing file attachments here
        allow(subject).to receive(:retrieve_mail_body_parts).and_return([])

        expected_attachments = [
          Attachment.new(
            path: '/tmp/output.pdf',
            type: 'output',
            mimetype: 'application/pdf',
            url: 'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf',
            filename: 'form1'
          ),
          Attachment.new(
            path: '/tmp/filestore.png',
            type: 'filestore',
            mimetype: 'image/png',
            url: 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev//service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8',
            filename: 'image2.png'
          )
        ]

        subject.send(:attachments, submission.detail_objects[0]).each_with_index do |a, i|
          %i[type filename url mimetype path].each do |k|
            expect(a.send(k)).to eql(expected_attachments[i].send(k))
          end
        end

        allow(subject).to receive(:attachments).and_return(expected_attachments)

        expect(EmailService).to receive(:send_mail).with(attachments: [expected_attachments[0]],
                                                         body_parts: [],
                                                         from: 'some.one@example.com',
                                                         subject: 'mail subject {id-of-submission} [1/2]',
                                                         to: 'destination@example.com')

        expect(EmailService).to receive(:send_mail).with(attachments: [expected_attachments[1]],
                                                         body_parts: [],
                                                         from: 'some.one@example.com',
                                                         subject: 'mail subject {id-of-submission} [2/2]',
                                                         to: 'destination@example.com')

        subject.perform
      end
    end
  end
end
