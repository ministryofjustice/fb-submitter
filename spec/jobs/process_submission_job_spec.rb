require 'rails_helper'

describe ProcessSubmissionJob do
  around :each do |example|
    Timecop.freeze(Time.new(2019, 5, 28, 9, 10)) do
      example.run
    end
  end

  let(:mock_downloaded_files) { {'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf' => '/path/to/file1', 'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid2.pdf' => '/path/to/file2'} }
  let(:downloaded_body_parts) { mock_downloaded_files }
  let(:body_part_content) do
    {
      'text/plain' => 'some plain text',
      'text/html' => '<html>some html</html>'
    }
  end
  let(:token) { 'some token' }
  let(:headers) do
    {
      'x-encrypted-user-id-and-token' => token,
      'x-access-token' => 'eyJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE1NTkwMzQ2MDB9.ftHMD2K6obQOqpm98wLD3y87Hf1F7jfac8tCa-QM_I8'
    }
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
        'attachments' => [
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
      }
    end
    let(:processed_attachments) do
      [
        Attachment.new({
          path: '/path/to/file1',
          type: 'output',
          mimetype: 'application/pdf',
          url: 'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf',
          filename: 'form1'
        }),
        Attachment.new({
          path: '/path/to/file2',
          type: 'output',
          mimetype: 'application/pdf',
          url: 'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid2.pdf',
          filename: 'form2'
        })
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
    let(:mock_send_response){ {'key' => 'send response'} }
    before do
      allow(EmailService).to receive(:send_mail).and_return( mock_send_response )
      allow(DownloadService).to receive(:download_in_parallel).and_return(
        mock_downloaded_files
      )
      allow(subject).to receive(:retrieve_mail_body_parts).and_return(body_part_content)
    end

    context 'given a valid submission_id' do
      let(:submission_id) { submission.id }

      before do
        allow(Submission).to receive(:find).with(submission_id).and_return(submission)
      end

      it 'loads the Submission' do
        expect(Submission).to receive(:find).with(submission_id).and_return(submission)
        subject.perform(submission_id: submission_id)
      end

      it 'updates the Submission status to :processing' do
        expect(submission).to receive(:update_status).with(:processing)
        subject.perform(submission_id: submission_id)
      end

      it 'gets the unique_attachment_urls' do
        expect(subject).to receive(:unique_attachment_urls).and_return(urls)
        subject.perform(submission_id: submission_id)
      end

      it 'downloads the resolved unique_attachment_urls in parallel' do
        expect(DownloadService).to receive(:download_in_parallel)
                                .with(urls: urls, headers: headers)
                                .and_return(mock_downloaded_files)
        subject.perform(submission_id: submission_id)
      end

      it 'gets the detail_objects from the Submission' do
        expect(submission).to receive(:detail_objects).at_least(:once).and_return(submission.detail_objects)
        subject.perform(submission_id: submission_id)
      end

      describe 'for each detail object' do
        let(:detail_object){ submission.detail_objects.first }

        it 'retrieves the mail body parts' do
          expect(subject).to receive(:retrieve_mail_body_parts).with(detail_object, headers).and_return(body_part_content)
          subject.perform(submission_id: submission_id)
        end

        it 'asks the EmailService to send an email' do
          allow(subject).to receive(:attachments).and_return(processed_attachments)

          expect(EmailService).to receive(:send_mail).with(
            from: detail_object.from,
            to: detail_object.to,
            subject: detail_object.subject,
            body_parts: body_part_content,
            attachments: processed_attachments
          ).and_return(mock_send_response)
          subject.perform(submission_id: submission_id)
        end

        it 'adds the response to the submission responses' do
          subject.perform(submission_id: submission_id)
          expect(submission.responses).to eq([mock_send_response])
        end

        it 'saves the submission' do
          expect(submission).to receive(:save!)
          subject.perform(submission_id: submission_id)
        end

        it 'completes the submission' do
          subject.perform(submission_id: submission_id)
          expect(submission.status).to eq('completed')
        end
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
        Submission.new(submission_details: [submission_detail_1, submission_detail_2])
      end

      it 'returns a single array of unique urls' do
        expect(subject.send(:unique_attachment_urls, submission)).to eq(
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
      allow(subject).to receive(:download_body_parts).with(mail, headers).and_return(mock_downloaded_files)
      allow(subject).to receive(:read_downloaded_body_parts).with(mail, mock_downloaded_files).and_return(body_part_content)
    end
    it 'downloads the body parts' do
      expect(subject).to receive(:download_body_parts).with(mail, headers).and_return(mock_downloaded_files)
      subject.send(:retrieve_mail_body_parts, mail, headers)
    end
    it 'reads the downloaded body parts' do
      expect(subject).to receive(:read_downloaded_body_parts).with(mail, mock_downloaded_files).and_return(body_part_content)
      subject.send(:retrieve_mail_body_parts, mail, headers)
    end
    it 'returns the map of content type to content' do
      expect(subject.send(:retrieve_mail_body_parts, mail, headers)).to eq(body_part_content)
    end
  end

  describe '#download_body_parts' do
    let(:mail) { double('mail', body_parts: {'text/plain' => 'url1', 'text/html' => 'url2'}) }
    before do
      allow(DownloadService).to receive(:download_in_parallel).with(
        urls: ['url1', 'url2'],
        headers: headers
      ).and_return('download result')
    end

    it 'asks the DownloadService to download the resolved body part urls in parallel' do
      expect(DownloadService).to receive(:download_in_parallel).with(
        urls: ['url1', 'url2'],
        headers: headers
      )
      subject.send(:download_body_parts, mail, headers)
    end

    it 'returns the result of the download call' do
      expect(subject.send(:download_body_parts, mail, headers)).to eq('download result')
    end
  end

  describe '#read_downloaded_body_parts' do
    context 'given a mail with body parts' do
      let(:mail) { double('mail', body_parts: {'text/plain' => 'url1', 'text/html' => 'url2'}) }

      context 'and a map of urls to file paths' do
        let(:file_map) { {'url1' => 'file1', 'url2' => 'file2'} }
        let(:mock_file_1) { double('File1', read: 'file 1 content')}
        let(:mock_file_2) { double('File2', read: 'file 2 content')}
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
      end

      it 'converts output urls to absolute urls' do
        url = submission.detail_objects.dig(0).attachments.dig(0, 'url')
        expect(url).to start_with('http')
      end

      it 'attaches filestore attachments' do
        expect(DownloadService).to receive(:download_in_parallel)
          .with(headers: {
            "x-encrypted-user-id-and-token" => "encrypted_user_id_and_token",
            "x-access-token" => headers['x-access-token']
          }, urls: [
            "http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev//service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8",
            "http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf"
          ]).and_return({
            "http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev//service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8" => "/tmp/filestore.png",
            "http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf" => "/tmp/output.pdf"
          })

        # only testing file attachments here
        allow(subject).to receive(:retrieve_mail_body_parts).and_return([])

        expected_attachments = [
          Attachment.new({
          path: '/tmp/output.pdf',
          type: 'output',
          mimetype: 'application/pdf',
          url: 'http://service-slug.formbuilder-services-test:3000/api/submitter/pdf/default/guid1.pdf',
          filename: 'form1'
        }),
        Attachment.new({
          path: '/tmp/filestore.png',
          type: 'filestore',
          mimetype: 'image/png',
          url: 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev//service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8',
          filename: 'image2.png'
        })]

        allow(subject).to receive(:attachments).and_return(expected_attachments)

        expect(EmailService).to receive(:send_mail).with(attachments: expected_attachments,
                                                         body_parts: [],
                                                         from: "some.one@example.com",
                                                         subject: "mail subject",
                                                         to: "destination@example.com")

        subject.perform(submission_id: 1)
      end
    end
  end
end
