require 'rails_helper'

describe DownloadService do
  let(:url) { 'https://my.domain/some/path/file.ext' }
  let(:token) { 'sometoken' }
  let(:access_token) { 'someaccesstoken' }
  let(:headers) do
    {
      'x-encrypted-user-id-and-token' => token,
      'x-access-token-v2' => access_token
    }
  end
  let(:mock_hydra) { instance_double(Typhoeus::Hydra) }
  let(:attachments) { [build(:attachment)] }
  let(:target_dir) { '/my/target/dir' }

  describe '#download_in_parallel' do
    subject(:downloader) do
      described_class.new(target_dir: target_dir,
                          token: token,
                          access_token: access_token)
    end

    let(:path) { '/the/file/path' }
    let(:mock_request) { instance_double(Typhoeus::Request) }

    before do
      allow(Typhoeus::Hydra).to receive(:hydra).and_return(mock_hydra)
      allow(mock_hydra).to receive(:run).and_return('run result')
      allow(mock_hydra).to receive(:queue).and_return('queue result')
      allow(downloader).to receive(:construct_request).and_return(mock_request)
      allow(mock_request).to receive(:run).and_return('run result')
      allow(downloader).to receive(:file_path_for_download).and_return(path + '/file.ext')
    end

    context 'when no target_dir is given' do
      let(:target_dir) { nil }

      before do
        allow(Dir).to receive(:mktmpdir).and_return('/a/new/temp/dir')
      end

      it 'makes a temp dir' do
        expect(Dir).to receive(:mktmpdir)
        downloader.download_in_parallel(attachments)
      end
    end

    context 'when a target_dir is given' do
      subject(:downloader) do
        described_class.new(target_dir: target_dir,
                            token: token,
                            access_token: access_token)
      end

      let(:target_dir) { '/my/tmp/dir' }

      it 'does not make a temp dir' do
        expect(Dir).not_to receive(:mktmpdir)
        downloader.download_in_parallel(attachments)
      end
    end

    context 'with an array of urls' do
      subject(:downloader) do
        described_class.new(target_dir: path,
                            token: token,
                            access_token: access_token)
      end

      let(:url1) { 'https://example.com/service/some-service/user/some-user/fingerprint' }
      let(:url2) { 'https://another.domain/some/otherfile.ext' }
      let(:mock_request_1) { instance_double(Typhoeus::Request) }
      let(:mock_request_2) { instance_double(Typhoeus::Request) }
      let(:download1) do
        build(:attachment, url: url1, mimetype: 'application/pdf', filename: 'evidence_one.pdf', type: 'filestore')
      end
      let(:download2) do
        build(:attachment, url: url2, mimetype: 'application/pdf', filename: 'evidence_two.pdf', type: 'filestore')
      end

      let(:attachments) { [download1, download2] }

      before do
        allow(downloader).to receive(:file_path_for_download).with(url: download1.url, target_dir: path).and_return('/tmp/file1')
        allow(downloader).to receive(:file_path_for_download).with(url: download2.url, target_dir: path).and_return('/tmp/file2')
        allow(downloader).to receive(:construct_request).with(url: download1.url, file_path: '/tmp/file1', headers: headers).and_return(mock_request_1)
        allow(downloader).to receive(:construct_request).with(url: download2.url, file_path: '/tmp/file2', headers: headers).and_return(mock_request_2)
      end

      describe 'for each url' do
        it 'gets the file_path_for_download' do
          expect(downloader).to receive(:file_path_for_download).with(url: url1, target_dir: path).and_return('/tmp/file1')
          expect(downloader).to receive(:file_path_for_download).with(url: url2, target_dir: path).and_return('/tmp/file2')
          downloader.download_in_parallel(attachments)
        end

        it 'constructs a request, passing the url and file path for download' do
          expect(downloader).to receive(:construct_request).with(url: url1, file_path: '/tmp/file1', headers: headers)
          expect(downloader).to receive(:construct_request).with(url: url2, file_path: '/tmp/file2', headers: headers)
          downloader.download_in_parallel(attachments)
        end

        it 'includes x-access-token header with JWT' do
          time = Time.new(2019, 1, 1, 13, 57).utc

          Timecop.freeze(time) do
            allow(downloader).to receive(:construct_request).and_call_original

            expected_url1 = 'https://example.com/service/some-service/user/some-user/fingerprint'
            expected_url2 = 'https://another.domain/some/otherfile.ext'

            expect(Typhoeus::Request).to receive(:new).with(expected_url1, followlocation: true, headers: headers).and_return(double.as_null_object)
            expect(Typhoeus::Request).to receive(:new).with(expected_url2, followlocation: true, headers: headers).and_return(double.as_null_object)

            downloader.download_in_parallel(attachments)
          end
        end

        it 'queues the request' do
          expect(mock_hydra).to receive(:queue).with(mock_request_1)
          expect(mock_hydra).to receive(:queue).with(mock_request_2)
          downloader.download_in_parallel(attachments)
        end
      end

      it 'runs the request batch' do
        expect(mock_hydra).to receive(:run)
        downloader.download_in_parallel(attachments)
      end

      it 'returns an array of Attachment objects with all file info plus local paths' do
        response = downloader.download_in_parallel(attachments)
        expect(response.each.map(&:class).uniq).to eq([Attachment])
      end

      it 'assigns the correct values to the Attachment objects' do
        response = downloader.download_in_parallel(attachments)
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
    end
  end

  context 'when the network request is unsuccessful' do
    subject(:downloader) do
      described_class.new(target_dir: target_dir,
                          token: token,
                          access_token: access_token)
    end

    let(:mock_request) { instance_double(Typhoeus::Request, url: 'some_url') }
    let(:good_response) { instance_double(Typhoeus::Response, code: 200, return_code: 200) }
    let(:bad_response) { instance_double(Typhoeus::Response, code: 500, return_code: 500) }
    let(:attachments) { [build(:attachment)] }

    context 'when failure is on headers' do
      before do
        allow(Typhoeus::Request).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:on_headers).and_yield(bad_response)
      end

      it 'raises the correct error' do
        expect { downloader.download_in_parallel(attachments) }.to raise_error(
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
        expect { downloader.download_in_parallel(attachments) }.to raise_error(
          RuntimeError, 'Request failed (500: 500 some_url)'
        )
      end
    end
  end
end
