require 'rails_helper'

describe DownloadService do
  let(:url) { 'https://my.domain/some/path/file.ext' }
  let(:headers) { { 'x-encrypted-user-id-and-token' => 'sometoken' } }
  let(:args) { { url: url, target_dir: '/my/target/dir', headers: headers } }
  let(:mock_hydra) { instance_double(Typhoeus::Hydra) }

  before do
    allow(Typhoeus::Hydra).to receive(:hydra).and_return(mock_hydra)
    allow(mock_hydra).to receive(:run).and_return('run result')
    allow(mock_hydra).to receive(:queue).and_return('queue result')
  end

  describe '#download_in_parallel' do
    subject do
      described_class.new(urls: [url])
    end

    let(:path) { '/the/file/path' }
    let(:mock_request) { instance_double(Typhoeus::Request) }

    before do
      allow(subject).to receive(:construct_request).and_return(mock_request)
      allow(mock_request).to receive(:run).and_return('run result')
      allow(subject).to receive(:file_path_for_download).and_return(path + '/file.ext')
    end

    context 'when no target_dir is given' do
      before do
        allow(Dir).to receive(:mktmpdir).and_return('/a/new/temp/dir')
      end

      it 'makes a temp dir' do
        expect(Dir).to receive(:mktmpdir)
        subject.download_in_parallel
      end
    end

    context 'when a target_dir is given' do
      subject do
        described_class.new(urls: [url], target_dir: target_dir)
      end

      let(:target_dir) { '/my/tmp/dir' }

      it 'does not make a temp dir' do
        expect(Dir).not_to receive(:mktmpdir)
        subject.download_in_parallel
      end
    end

    context 'given an array of urls' do
      subject do
        described_class.new(args)
      end

      let(:url1) { 'https://example.com/service/some-service/user/some-user/fingerprint' }
      let(:url2) { 'https://another.domain/some/otherfile.ext' }
      let(:args) { { urls: [url1, url2], target_dir: path, headers: headers } }
      let(:mock_request_1) { instance_double(Typhoeus::Request) }
      let(:mock_request_2) { instance_double(Typhoeus::Request) }

      before do
        allow(subject).to receive(:file_path_for_download).with(url: url1, target_dir: path).and_return('/tmp/file1')
        allow(subject).to receive(:file_path_for_download).with(url: url2, target_dir: path).and_return('/tmp/file2')
        allow(subject).to receive(:construct_request).with(url: url1, file_path: '/tmp/file1', headers: headers).and_return(mock_request_1)
        allow(subject).to receive(:construct_request).with(url: url2, file_path: '/tmp/file2', headers: headers).and_return(mock_request_2)
      end

      describe 'for each url' do
        it 'gets the file_path_for_download' do
          expect(subject).to receive(:file_path_for_download).with(url: url1, target_dir: path).and_return('/tmp/file1')
          expect(subject).to receive(:file_path_for_download).with(url: url2, target_dir: path).and_return('/tmp/file2')
          subject.download_in_parallel
        end

        it 'constructs a request, passing the url and file path for download' do
          expect(subject).to receive(:construct_request).with(url: url1, file_path: '/tmp/file1', headers: headers)
          expect(subject).to receive(:construct_request).with(url: url2, file_path: '/tmp/file2', headers: headers)
          subject.download_in_parallel
        end

        it 'includes x-access-token header with JWT' do
          time = Time.new(2019, 1, 1, 13, 57).utc

          Timecop.freeze(time) do
            allow(subject).to receive(:construct_request).and_call_original

            expected_url1 = 'https://example.com/service/some-service/user/some-user/fingerprint'
            expected_url2 = 'https://another.domain/some/otherfile.ext'
            expected_headers = { 'x-encrypted-user-id-and-token' => 'sometoken' }

            expect(Typhoeus::Request).to receive(:new).with(expected_url1, followlocation: true, headers: expected_headers).and_return(double.as_null_object)
            expect(Typhoeus::Request).to receive(:new).with(expected_url2, followlocation: true, headers: expected_headers).and_return(double.as_null_object)

            subject.download_in_parallel
          end
        end

        it 'queues the request' do
          expect(mock_hydra).to receive(:queue).with(mock_request_1)
          expect(mock_hydra).to receive(:queue).with(mock_request_2)
          subject.download_in_parallel
        end
      end

      it 'runs the request batch' do
        expect(mock_hydra).to receive(:run)
        subject.download_in_parallel
      end

      it 'returns the urls mapped to file paths' do
        expect(subject.download_in_parallel).to eq(
          url1 => '/tmp/file1',
          url2 => '/tmp/file2'
        )
      end
    end
  end
end
