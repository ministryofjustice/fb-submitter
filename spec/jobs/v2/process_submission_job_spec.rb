require 'rails_helper'
require 'webmock/rspec'

RSpec.describe V2::ProcessSubmissionJob do
  subject(:job) { described_class.new }

  describe '#perform' do
    subject(:perform_job) do
      job.perform(submission_id: submission.id)
    end

    let(:key) { SecureRandom.uuid[0..31] }
    let(:submission) do
      create(:submission, payload: encrypted_payload, access_token:)
    end
    let(:payload_fixture) do
      JSON.parse(File.read(Rails.root.join('spec/fixtures/payloads/valid_submission.json')))
    end
    let(:access_token) do
      'jar-jar-binks'
    end
    let(:expected_pdf_request_body) do
      JSON.parse(File.read(
                   Rails.root.join('spec/fixtures/payloads/pdf_generator.json')
                 )).merge('submission_id' => submission.id)
    end
    let(:email_output_service) { instance_spy(EmailOutputService) }
    let(:ms_graph_service) { instance_spy(V2::SendToMsGraphService) }
    let(:generated_pdf_content) do
      "I'm one with the Force. The Force is with me.\n"
    end

    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('SUBMISSION_DECRYPTION_KEY').and_return(key)
      allow(EmailOutputService).to receive(:new).and_return(email_output_service)
      allow(V2::SendToMsGraphService).to receive(:new).and_return(ms_graph_service)
    end

    context 'when email action' do
      let(:encrypted_payload) do
        fixture = payload_fixture
        fixture['actions'] = fixture['actions'].select { |action| action['kind'] == 'email' }
        SubmissionEncryption.new(key:).encrypt(fixture)
      end
      let(:expected_action) do
        {
          subject: 'Email Output Acceptance Test submission: fc242acb-c03f-439e-b41d-bec76fa0f032',
          to: 'captain.needa@star-destroyer.com,admiral.piett@star-destroyer.com'
        }
      end

      before do
        stub_request(:post, 'http://pdf-generator-api:3000/v1/pdfs')
          .with(body: expected_pdf_request_body)
          .to_return(status: 200, body: generated_pdf_content, headers: {})

        stub_request(:get, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/dog-contest/user/1/123')
          .to_return(status: 200, body: 'image', headers: {})
      end

      it 'sends the email with pdf attachment' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          pdf_contents = File.open(args[:pdf_attachment].path).read
          expect(pdf_contents).to eq(generated_pdf_content)
        end
      end

      it 'sends email with attachments' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          expect(args[:attachments].length).to eq(1)
          expect(args[:attachments].first.filename).to match(/basset-hound-dog-picture.png/)
        end
      end

      it 'sends the email with subject' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          expect(args[:action]).to include(expected_action)
        end
      end
    end

    context 'when email action without attachments' do
      let(:encrypted_payload) do
        fixture = payload_fixture
        fixture['actions'] = fixture['actions'].select { |action| action['kind'] == 'email' }
        fixture['actions'].each { |action| action['include_attachments'] = false }
        SubmissionEncryption.new(key:).encrypt(fixture)
      end
      let(:expected_action) do
        {
          subject: 'Email Output Acceptance Test submission: fc242acb-c03f-439e-b41d-bec76fa0f032',
          to: 'captain.needa@star-destroyer.com,admiral.piett@star-destroyer.com'
        }
      end

      before do
        stub_request(:post, 'http://pdf-generator-api:3000/v1/pdfs')
          .with(body: expected_pdf_request_body)
          .to_return(status: 200, body: generated_pdf_content, headers: {})
      end

      it 'sends the email with pdf attachment' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          pdf_contents = File.open(args[:pdf_attachment].path).read
          expect(pdf_contents).to eq(generated_pdf_content)
        end
      end

      it 'sends email with no attachments' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          expect(args[:attachments]).to eq([])
        end
      end

      it 'sends the email with subject' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          expect(args[:action]).to include(expected_action)
        end
      end
    end

    context 'when email action without pdf attachment' do
      let(:encrypted_payload) do
        fixture = payload_fixture
        fixture['actions'] = fixture['actions'].select { |action| action['kind'] == 'email' }
        fixture['actions'].each { |action| action['include_pdf'] = false }
        SubmissionEncryption.new(key:).encrypt(fixture)
      end

      before do
        stub_request(:get, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/dog-contest/user/1/123')
          .to_return(status: 200, body: 'image', headers: {})
      end

      it 'sends email with attachments' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          expect(args[:attachments].length).to eq(1)
          expect(args[:attachments].first.filename).to match(/basset-hound-dog-picture.png/)
        end
      end

      it 'sends email without pdf attachment' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          expect(args[:pdf_attachment]).to be_nil
        end
      end
    end

    context 'when email action without pdf and without attachments' do
      let(:encrypted_payload) do
        fixture = payload_fixture
        fixture['actions'] = fixture['actions'].select { |action| action['kind'] == 'email' }
        fixture['actions'].each do |action|
          action['include_pdf'] = false
          action['include_attachments'] = false
        end
        SubmissionEncryption.new(key:).encrypt(fixture)
      end

      it 'sends email without attachments' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          expect(args[:attachments]).to eq([])
        end
      end

      it 'sends email without pdf attachment' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          expect(args[:pdf_attachment]).to be_nil
        end
      end
    end

    context 'when microsoft graph api action' do
      let(:key) { SecureRandom.uuid[0..31] }
      let(:submission) do
        create(:submission, payload: encrypted_payload, access_token:)
      end
      let(:fixture) { payload_fixture }
      let(:payload_fixture) do
        JSON.parse(File.read(Rails.root.join('spec/fixtures/payloads/valid_submission.json')))
      end
      let(:access_token) do
        'jar-jar-binks'
      end
      let(:action) { fixture['actions'].select { |action| action['kind'] == 'mslist' }.first }
      let(:encrypted_payload) do
        fixture['actions'] = fixture['actions'].select { |action| action['kind'] == 'mslist' }
        SubmissionEncryption.new(key:).encrypt(fixture)
      end
      let(:response) do
        {
          webUrl: 'i_am_the_drive_url'
        }
      end

      context 'when including attachments' do
        let(:payload_fixture) do
          JSON.parse(File.read(Rails.root.join('spec/fixtures/payloads/valid_submission_with_file.json')))
        end

        before do
          # download attachment stub
          stub_request(:get, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/dog-contest/user/1/123')
            .to_return(status: 200, body: 'image', headers: {})

          # download attachment stub
          stub_request(:get, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/dog-contest/user/1/456')
            .to_return(status: 200, body: 'image', headers: {})

          # post to graph api stub
          stub_request(:post, 'https://rooturl.graph.example.com/sites/site_id/drive/items/root:/basset-hound-dog-picture.png:/content')
            .to_return(status: 200, body: response.to_json, headers: {})

          # post to graph api stub
          stub_request(:post, 'https://rooturl.graph.example.com/sites/site_id/drive/items/root:/basset-hound-dog-picture+(1).png:/content')
          .to_return(status: 200, body: response.to_json, headers: {})

          # post create folder stub
          stub_request(:post, 'https://rooturl.graph.example.com/sites/site_id/drive/items/root/children')
          .to_return(status: 201, body: { id: 'a-folder' }.to_json, headers: {})

          # post to list
          stub_request(:post, 'https://rooturl.graph.example.com/sites/site_id/lists/list_id')
            .to_return(status: 200, body: response.to_json, headers: {})

          # auth url call
          stub_request(:post, 'https://authurl.example.com')
            .to_return(status: 200, body: { 'access_token' => 'valid_token' }.to_json, headers: {})

          allow(ENV).to receive(:[])

          allow(ENV).to receive(:[]).with('SUBMISSION_DECRYPTION_KEY').and_return(key)
          allow(EmailOutputService).to receive(:new).and_return(email_output_service)
          allow(ms_graph_service).to receive(:create_folder_in_drive).and_return('a-folder')
          allow(ms_graph_service).to receive(:send_attachment_to_drive).and_return({ 'webUrl' => 'https://drive/basset-hound-dog-picture.png' }, { 'webUrl' => 'https://drive/basset-hound-dog-picture+(1).png' })
        end

        it 'sends attachments to drive' do
          perform_job

          expect(ms_graph_service).to have_received(:send_attachment_to_drive).exactly(2).times
        end

        it 'sends to graph api with drive links' do
          perform_job

          expect(ms_graph_service).to have_received(:post_to_ms_list) do |arg1, arg2|
            expect(arg1['actions'][0]['kind']).to eq('mslist')
            expect(arg1['pages'][1]['answers'][0]['answer']).to include('https://drive/basset-hound-dog-picture.png')
            expect(arg1['pages'][1]['answers'][0]['answer']).to include('https://drive/basset-hound-dog-picture+(1).png')
            expect(arg2).to eq(submission.id)
          end
        end
      end
    end

    context 'when csv action' do
      let(:encrypted_payload) do
        fixture = payload_fixture
        fixture['actions'] = fixture['actions'].select { |action| action['kind'] == 'csv' }
        SubmissionEncryption.new(key:).encrypt(fixture)
      end
      let(:expected_action) do
        {
          kind: 'csv',
          variant: nil,
          subject: 'CSV Output Acceptance Test submission: fc242acb-c03f-439e-b41d-bec76fa0f032',
          to: 'captain.needa@star-destroyer.com,admiral.piett@star-destroyer.com',
          from: '"Email Output Acceptance Test Service" <moj-online@digital.justice.gov.uk>',
          email_body: '',
          include_attachments: true,
          include_pdf: false
        }
      end

      it 'sends an email with a csv attachment' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          expect(args[:action]).to include(expected_action)
        end
      end
    end

    context 'when JSON API action' do
      let(:encrypted_payload) do
        fixture = payload_fixture
        fixture['actions'] = fixture['actions'].select { |action| action['kind'] == 'json' }
        SubmissionEncryption.new(key:).encrypt(fixture)
      end

      let(:json_webhook_service_spy) { instance_spy(JsonWebhookService) }

      before do
        allow(JsonWebhookService).to receive(:new).and_return(json_webhook_service_spy)
        perform_job
      end

      it 'passes the correct collaborators to the JsonWebhookService' do
        expect(JsonWebhookService).to have_received(:new) do |args|
          expect(args[:webhook_attachment_fetcher]).to be_an_instance_of(WebhookAttachmentService)
          expect(args[:webhook_destination_adapter]).to be_an_instance_of(Adapters::JweWebhookDestination)
        end
      end

      it 'passes the correct user_answers payload as an argument' do
        decrypted_payload = SubmissionEncryption.new(key:).decrypt(submission[:payload])
        user_answers = V2::SubmissionPayloadService.new(decrypted_payload).user_answers
        expect(json_webhook_service_spy).to have_received(:execute) do |args|
          expect(args[:user_answers]).to eq(user_answers)
        end
      end

      it 'passes the correct service_slug as an argument' do
        expect(json_webhook_service_spy).to have_received(:execute) do |args|
          expect(args[:service_slug]).to eq(submission.service_slug)
        end
      end
    end

    context 'when the action is not recognised' do
      let(:encrypted_payload) do
        fixture = payload_fixture
        fixture['actions'] = [{ 'kind' => 'foobar' }]
        SubmissionEncryption.new(key:).encrypt(fixture)
      end

      before do
        allow(Rails.logger).to receive(:warn)
        perform_job
      end

      it 'logs a warning' do
        expect(Rails.logger).to have_received(:warn).with(/Unknown action type/)
      end
    end
  end
end
