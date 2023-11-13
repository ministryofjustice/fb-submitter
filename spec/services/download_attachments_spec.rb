require 'rails_helper'
require 'webmock/rspec'

describe DownloadAttachments do
  subject(:downloader) do
    described_class.new(
      attachments:,
      encrypted_user_id_and_token:,
      access_token:,
      request_id:,
      target_dir:,
      jwt_skew_override:,
    )
  end

  let(:url) { 'https://my.domain/some/path/file.ext' }
  let(:encrypted_user_id_and_token) { 'sometoken' }
  let(:access_token) { 'someaccesstoken' }
  let(:request_id) { '12345' }
  let(:jwt_skew_override) { nil }

  let(:headers) do
    {
      'x-encrypted-user-id-and-token' => encrypted_user_id_and_token,
      'x-access-token-v2' => access_token,
      'X-Request-Id' => request_id,
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
    stub_request(:get, url).with(headers:)
      .to_return(status: 200, body: 'THAT IS NOT A KNIFE', headers: {})
  end

  # rubocop:disable RSpec/StubbedMock
  describe '#download' do
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
        expect(File).to receive(:open).with('/my/tmp/dir/file.ext', 'wb')

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
          .with(url: url1).and_return('/tmp/file1')
        allow(downloader).to receive(:file_path_for_download)
          .with(url: url2).and_return('/tmp/file2')
        allow(downloader).to receive(:request)
          .with(url: url1, file_path: '/tmp/file1', headers:)
        allow(downloader).to receive(:request)
          .with(url: url2, file_path: '/tmp/file2', headers:)
      end

      describe 'for each url' do
        it 'gets the file_path_for_download' do
          expect(downloader).to receive(:file_path_for_download)
            .with(url: url1).and_return('/tmp/file1')
          expect(downloader).to receive(:file_path_for_download)
            .with(url: url2).and_return('/tmp/file2')
          downloader.download
        end

        it 'constructs a request, passing the url and file path for download' do
          expect(downloader).to receive(:request)
            .with(url: url1, file_path: '/tmp/file1', headers:)
          expect(downloader).to receive(:request)
            .with(url: url2, file_path: '/tmp/file2', headers:)
          downloader.download
        end

        it 'includes x-access-token header with JWT' do
          time = Time.zone.local(2019, 1, 1, 13, 57).utc

          Timecop.freeze(time) do
            allow(downloader).to receive(:request).and_call_original

            expected_url1 = 'https://example.com/service/some-service/user/some-user/fingerprint'
            expected_url2 = 'https://another.domain/some/otherfile.ext'

            expect(Faraday).to receive(:new).with(expected_url1).and_return(double.as_null_object)
            expect(Faraday).to receive(:new).with(expected_url2).and_return(double.as_null_object)

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
        let(:jwt_skew_override) { '600' }

        it 'sends the jwt skew override with the other headers' do
          expected_headers = headers.merge('x-jwt-skew-override' => '600')
          expect(downloader).to receive(:request)
            .with(
              url: url1,
              file_path: '/tmp/file1',
              headers: expected_headers
            )
          expect(downloader).to receive(:request)
            .with(
              url: url2,
              file_path: '/tmp/file2',
              headers: expected_headers
            )

          downloader.download
        end
      end
    end
  end
  # rubocop:enable RSpec/StubbedMock

  context 'when the network request is unsuccessful' do
    let(:mock_request) { double }
    let(:bad_response) { instance_double(Faraday::Response, code: 500, return_code: 500) }

    context 'when failure' do
      before do
        allow(Faraday).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:get).and_raise(Faraday::ConnectionFailed, '')
      end

      it 'raises the correct error' do
        expect { downloader.download }.to raise_error(
          Faraday::ConnectionFailed
        )
      end
    end
  end
end
