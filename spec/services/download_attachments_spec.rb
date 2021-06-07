require 'rails_helper'
require 'webmock/rspec'

describe DownloadAttachments do
  subject(:downloader) do
    described_class.new(
      attachments: attachments,
      target_dir: target_dir,
      token: token,
      access_token: access_token,
      jwt_skew_override: nil
    )
  end
  let(:url) { 'https://my.domain/some/path/file.ext' }
  let(:token) { 'sometoken' }
  let(:access_token) { 'someaccesstoken' }
  let(:headers) do
    {
      'x-encrypted-user-id-and-token' => token,
      'x-access-token-v2' => access_token
    }
  end
  let(:attachments) do
    [
      'url' => url,
      'mimetype' => 'application/pdf',
      'filename' => 'evidence_one.pdf',
      'type' => 'filestore'
    ]
  end
  let(:target_dir) { '/my/target/dir' }

  before do
    stub_request(:get, url).with(headers: headers)
      .to_return(status: 200, body: 'THAT IS NOT A KNIFE', headers: {})
  end

  describe '#download' do
    let(:path) { '/the/file/path' }

    context 'when no target_dir is given' do
      let(:target_dir) { nil }

      it 'makes a temp dir' do
        expect(Dir).to receive(:mktmpdir).and_return(Rails.root.join('tmp'))
        downloader.download
      end
    end

    context 'when a target_dir is given' do
      let(:target_dir) { '/my/tmp/dir' }

      it 'does not make a temp dir' do
        expect(Dir).not_to receive(:mktmpdir)
        downloader.download
      end
    end

    context 'with an array of urls' do
      let(:url1) do
        'https://example.com/service/some-service/user/some-user/fingerprint'
      end
      let(:url2) { 'https://another.domain/some/otherfile.ext' }
      let(:attachments) do
        [
          {
            'url' => url1,
            'mimetype' => 'application/pdf',
            'filename' => 'evidence_one.pdf',
            'type' => 'filestore'
          },
          {
            'url' => url2,
            'mimetype' => 'application/pdf',
            'filename' => 'evidence_two.pdf',
            'type' => 'filestore'
          }
        ]
      end

      before do
        allow(downloader).to receive(:file_path_for_download)
          .with(url: url1, target_dir: path).and_return('/tmp/file1')
        allow(downloader).to receive(:file_path_for_download)
          .with(url: url2, target_dir: path).and_return('/tmp/file2')
        allow(downloader).to receive(:request)
          .with(url: url1, file_path: '/tmp/file1', headers: headers)
        allow(downloader).to receive(:request)
          .with(url: url2, file_path: '/tmp/file2', headers: headers)
      end

      describe 'for each url' do
        it 'gets the file_path_for_download' do
          expect(downloader).to receive(:file_path_for_download)
            .with(url: url1, target_dir: path).and_return('/tmp/file1')
          expect(downloader).to receive(:file_path_for_download)
            .with(url: url2, target_dir: path).and_return('/tmp/file2')
          downloader.download
        end

        it 'constructs a request, passing the url and file path for download' do
          expect(downloader).to receive(:request)
            .with(url: url1, file_path: '/tmp/file1', headers: headers)
          expect(downloader).to receive(:request)
            .with(url: url2, file_path: '/tmp/file2', headers: headers)
          downloader.download
        end

        it 'includes x-access-token header with JWT' do
          pending
          time = Time.zone.local(2019, 1, 1, 13, 57).utc

          Timecop.freeze(time) do
            allow(downloader).to receive(:request).and_call_original

            expected_url1 = 'https://example.com/service/some-service/user/some-user/fingerprint'
            expected_url2 = 'https://another.domain/some/otherfile.ext'

#            expect(Faraday).to receive(:new).with(expected_url1, followlocation: true, headers: headers).and_return(double.as_null_object)
#            expect(Faraday).to receive(:new).with(expected_url2, followlocation: true, headers: headers).and_return(double.as_null_object)

            downloader.download
          end
        end
      end

      it 'returns an array of Attachment objects with all file info plus local paths' do
        response = downloader.download
        expect(response.each.map(&:class).uniq).to eq([Attachment])
      end

      it 'assigns the correct values to the Attachment objects' do
        response = downloader.download
        attachment_values = []

        response.each do |attachment|
          attachment_values << {
            url: attachment.url,
            filename: attachment.filename,
            mimetype: attachment.mimetype,
            path: attachment.path
          }
        end
        expect(attachment_values).to eq(
          [
            {
              filename: 'evidence_one.pdf',
              mimetype: 'application/pdf',
              path: '/tmp/file1',
              url: 'https://example.com/service/some-service/user/some-user/fingerprint'
            },
            {
              filename: 'evidence_two.pdf',
              mimetype: 'application/pdf',
              path: '/tmp/file2',
              url: 'https://another.domain/some/otherfile.ext'
            }
          ]
        )
      end

      context 'when a jwt skew override is supplied' do
        subject(:downloader) do
          described_class.new(attachments: attachments,
                              target_dir: target_dir,
                              token: token,
                              access_token: access_token,
                              jwt_skew_override: '600')
        end

        it 'sends the jwt skew override with the other headers' do
          expected_headers = headers.merge('x-jwt-skew-override' => '600')
          expect(downloader).to receive(:request)
            .with(
              url: url1,
              file_path: '/the/file/path/file.ext',
              headers: expected_headers
            )

          downloader.download
        end
      end
    end
  end

  context 'when the network request is unsuccessful' do
    subject(:downloader) do
      described_class.new(attachments: attachments,
                          target_dir: target_dir,
                          token: token,
                          access_token: access_token,
                          jwt_skew_override: nil)
    end

    let(:mock_request) { instance_double(Typhoeus::Request, url: 'some_url') }
    let(:good_response) { instance_double(Typhoeus::Response, code: 200, return_code: 200) }
    let(:bad_response) { instance_double(Typhoeus::Response, code: 500, return_code: 500) }

    context 'when failure is on headers' do
      before do
        allow(Typhoeus::Request).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:on_headers).and_yield(bad_response)
      end

      it 'raises the correct error' do
        expect { downloader.download }.to raise_error(
          RuntimeError, 'Request failed (500: 500 some_url)'
        )
      end
    end

    context 'when failure is on complete' do
      let(:file) { instance_double(File, write: true, close: true) }

      before do
        allow(File).to receive(:open).and_return(file)
        allow(Typhoeus::Request).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:on_headers).and_yield(good_response)
        allow(mock_request).to receive(:on_body).and_yield('')
        allow(mock_request).to receive(:on_complete).and_yield(bad_response)
      end

      it 'raises the correct error' do
        expect { downloader.download }.to raise_error(
          RuntimeError, 'Request failed (500: 500 some_url)'
        )
      end
    end
  end
end
