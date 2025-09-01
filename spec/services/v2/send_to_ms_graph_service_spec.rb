require 'rails_helper'
require 'webmock/rspec'

RSpec.describe V2::SendToMsGraphService do
  subject(:graph_service) { described_class.new(JSON.parse(action), 'service-slug') }

  let(:submission_id) { SecureRandom.uuid }
  let(:submission_at) { Time.zone.now.iso8601(3) }
  let(:payload) do
    {
      'submission_id' => submission_id,
      'meta' => {
        'pdf_heading' => 'Submission for new-runner-acceptance-tests',
        'pdf_subheading' => 'Submission subheading for new-runner-acceptance-tests',
        'submission_at' => submission_at
      },
      'service' => {
        'id' => SecureRandom.uuid,
        'slug' => 'new-runner-acceptance-tests',
        'name' => 'new runner acceptance tests'
      },
      'actions' => [
        {
          "kind": 'mslist',
          "variant": '',
          "graph_url": 'https://graph-url.microsoft.com',
          "site_id": '1234',
          "list_id": '5678',
          "drive_id": 'root',
          "reference_number": 'ref-123-xyz',
          "include_attachments": true
        }
      ],
      'pages' => [
        {
          'heading' => 'Your name',
          'answers' => [
            {
              'field_id' => 'name_text_1',
              'field_name' => 'First name',
              'answer' => 'Stormtrooper'
            },
            {
              'field_id' => 'name_text_2',
              'field_name' => 'Last name',
              'answer' => 'FN-b0046eb3-37ff-400d-85f8-8bbb5c11183b'
            }
          ]
        },
        {
          'heading' => '',
          'answers' => [
            {
              'field_id' => 'your-email-address_text_1',
              'field_name' => 'Your email address',
              'answer' => 'fb-acceptance-tests@digital.justice.gov.uk'
            }
          ]
        },
        {
          'heading' => '',
          'answers' => [
            {
              'field_id' => 'postal-address_address_1',
              'field_name' => 'Your postal address',
              'answer' => {
                'address_line_one' => '1 road',
                'address_line_two' => '',
                'city' => 'ruby town',
                'county' => '',
                'postcode' => '99 999',
                'country' => 'ruby land'
              }
            }
          ]
        }
      ],
      'attachments' => [
        {
          'url ' => 'http://the-filestore-url-for-attachment',
          'filename' => 'hello_world.txt',
          'mimetype' => 'text/plain'
        }
      ]
    }
  end
  let(:action) { payload['actions'][0].to_json }

  context 'when creating a folder for this submission' do
    context 'when successful' do
      before do
        stub_request(:post, 'https://graph-url.microsoft.com/sites/1234/drive/items/root/children')
        .to_return(status: 201, body: { id: 'a-folder' }.to_json, headers: {})

        stub_request(:post, 'https://authurl.example.com')
          .to_return(status: 200, body: { 'access_token' => 'valid_token' }.to_json, headers: {})

        allow(ENV).to receive(:[])

        allow(ENV).to receive(:[]).with('MS_OAUTH_URL').and_return('https://authurl.example.com')
      end

      it 'returns the drive id' do
        expect(graph_service.create_folder_in_drive(submission_id)).to eq('a-folder')
      end
    end

    context 'when api responds with error' do
      before do
        stub_request(:post, 'https://graph-url.microsoft.com/sites/1234/drive/items/root/children')
        .to_return(status: 500, body: {}.to_json, headers: {})

        stub_request(:post, 'https://authurl.example.com')
          .to_return(status: 200, body: { 'access_token' => 'valid_token' }.to_json, headers: {})

        allow(ENV).to receive(:[])

        allow(ENV).to receive(:[]).with('MS_OAUTH_URL').and_return('https://authurl.example.com')

        allow(Sentry).to receive(:capture_message)
      end

      it 'sends the error to sentry and defaults to the parent drive' do
        expect(graph_service.create_folder_in_drive(submission_id)).to eq('root')
        expect(Sentry).to have_received(:capture_message)
      end
    end
  end

  context 'when authenticating' do
    context 'when successful' do
      before do
        stub_request(:post, 'https://graph-url.microsoft.com/sites/1234/drive/items/root/children')
        .to_return(status: 500, body: {}.to_json, headers: {})

        stub_request(:post, 'https://authurl.example.com')
          .with(
            body: { 'client_id' => 'app_id', 'client_secret' => 'app_secret', 'grant_type' => 'client_credentials', 'resource' => 'https://graph.microsoft.com/' },
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Content-Type' => 'application/x-www-form-urlencoded',
              'User-Agent' => "Faraday v#{Faraday::VERSION}"
            }
          ).to_return(status: 200, body: { 'access_token' => 'valid_token' }.to_json, headers: {})

        allow(ENV).to receive(:[])

        allow(ENV).to receive(:[]).with('MS_OAUTH_URL').and_return('https://authurl.example.com')
        allow(ENV).to receive(:[]).with('MS_ADMIN_APP_ID').and_return('app_id')
        allow(ENV).to receive(:[]).with('MS_ADMIN_APP_SECRET').and_return('app_secret')
      end

      it 'calls the api with the form and return the value' do
        expect(graph_service.get_auth_token).to eq('valid_token')
      end
    end

    context 'when api responds with error' do
      before do
        stub_request(:post, 'https://graph-url.microsoft.com/sites/1234/drive/items/root/children')
        .to_return(status: 500, body: {}.to_json, headers: {})

        stub_request(:post, 'https://authurl.example.com')
          .with(
            body: { 'client_id' => 'app_id', 'client_secret' => 'app_secret', 'grant_type' => 'client_credentials', 'resource' => 'https://graph.microsoft.com/' },
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Content-Type' => 'application/x-www-form-urlencoded',
              'User-Agent' => "Faraday v#{Faraday::VERSION}"
            }
          ).to_return(status: 500, body: {}.to_json, headers: {})

        allow(ENV).to receive(:[])

        allow(ENV).to receive(:[]).with('MS_OAUTH_URL').and_return('https://authurl.example.com')
        allow(ENV).to receive(:[]).with('MS_ADMIN_APP_ID').and_return('app_id')
        allow(ENV).to receive(:[]).with('MS_ADMIN_APP_SECRET').and_return('app_secret')
      end

      it 'calls the api with the form and return the value' do
        expect { graph_service.get_auth_token }.to raise_error(Faraday::ServerError)
      end
    end

    context 'when permission denied' do
      before do
        stub_request(:post, 'https://graph-url.microsoft.com/sites/1234/drive/items/root/children')
        .to_return(status: 500, body: {}.to_json, headers: {})

        stub_request(:post, 'https://authurl.example.com')
          .with(
            body: { 'client_id' => 'app_id', 'client_secret' => 'app_secret', 'grant_type' => 'client_credentials', 'resource' => 'https://graph.microsoft.com/' },
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Content-Type' => 'application/x-www-form-urlencoded',
              'User-Agent' => "Faraday v#{Faraday::VERSION}"
            }
          ).to_return(status: 403, body: {}.to_json, headers: {})

        allow(ENV).to receive(:[])

        allow(ENV).to receive(:[]).with('MS_OAUTH_URL').and_return('https://authurl.example.com')
        allow(ENV).to receive(:[]).with('MS_ADMIN_APP_ID').and_return('app_id')
        allow(ENV).to receive(:[]).with('MS_ADMIN_APP_SECRET').and_return('app_secret')
      end

      it 'calls the api with the form and return the value' do
        expect { graph_service.get_auth_token }.to raise_error(Faraday::ForbiddenError)
      end
    end
  end

  context 'when sending attachment to drive' do
    let(:response) do
      {
        'webUrl' => 'file_in_drive'
      }
    end
    let(:attachment) { instance_spy(Attachment) }

    context 'when successful' do
      before do
        stub_request(:put, 'https://graph-url.microsoft.comsites/1234/drive/items/folder_path:/file+name.png:/content')
          .with(
            body: "hello world\n",
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Bearer valid_token',
              'Content-Type' => 'text/plain',
              'User-Agent' => "Faraday v#{Faraday::VERSION}"
            }
          )
          .to_return(status: 200, body: response.to_json, headers: {})

        stub_request(:post, 'https://authurl.example.com')
          .to_return(status: 200, body: { 'access_token' => 'valid_token' }.to_json, headers: {})

        allow(ENV).to receive(:[])

        allow(ENV).to receive(:[]).with('MS_OAUTH_URL').and_return('https://authurl.example.com')

        allow(attachment).to receive_messages(filename: 'file name.png', path: Rails.root.join('spec/fixtures/files/hello_world.txt'))
      end

      it 'returns file info' do
        expect(graph_service.send_attachment_to_drive(attachment, submission_id, 'folder_path')).to eq(response)
      end
    end
  end

  context 'when sending answers to list' do
    context 'when successful' do
      let(:response) do
        {
          'list_updated' => 'today'
        }
      end

      let(:answers_payload) do
        {
          'fields' =>
          {
            'debcefbcbdf' => submission_id,
            'bdfaeebcbe' => 'ref-123-xyz',
            'bfebbbeafabacdef' => 'Stormtrooper',
            'cbddedd' => 'FN-b0046eb3-37ff-400d-85f8-8bbb5c11183b',
            'dddddbccfbd' => 'fb-acceptance-tests@digital.justice.gov.uk',
            'bebcdcfeeeda' => 'postal-address_address_1; Your postal address; {"address_line_one"=>"1 road", "address_line_two"=>"", "city"=>"ruby town", "county"=>"", "postcode"=>"99 999", "country"=>"ruby land"}'
          }
        }
      end

      before do
        stub_request(:post, 'https://graph-url.microsoft.com/sites/1234/lists/5678/items')
          .with(
            body: answers_payload.to_json,
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Bearer valid_token',
              'Content-Type' => 'application/json',
              'User-Agent' => "Faraday v#{Faraday::VERSION}"
            }
          )
          .to_return(status: 200, body: response.to_json, headers: {})

        stub_request(:post, 'https://authurl.example.com')
          .to_return(status: 200, body: { 'access_token' => 'valid_token' }.to_json, headers: {})

        allow(ENV).to receive(:[])

        allow(ENV).to receive(:[]).with('MS_OAUTH_URL').and_return('https://authurl.example.com')
      end

      it 'returns returns the api response' do
        expect(graph_service.post_to_ms_list(payload, submission_id)).to eq(response)
      end
    end
  end
end
