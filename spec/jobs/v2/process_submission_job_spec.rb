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
    let(:email_output_service) { instance_spy(EmailOutputServiceV2) }
    let(:generated_pdf_content) do
      "I'm one with the Force. The Force is with me.\n"
    end

    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('SUBMISSION_DECRYPTION_KEY').and_return(key)
      allow(EmailOutputServiceV2).to receive(:new).and_return(email_output_service)
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
        stub_request(:post, 'http://pdf-generator.com/v1/pdfs')
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

    context 'when csv action' do
      let(:encrypted_payload) do
        fixture = payload_fixture
        fixture['actions'] = fixture['actions'].select { |action| action['kind'] == 'csv' }
        SubmissionEncryption.new(key:).encrypt(fixture)
      end
      let(:expected_action) do
        {
          kind: 'csv',
          subject: 'CSV Output Acceptance Test submission: fc242acb-c03f-439e-b41d-bec76fa0f032',
          to: 'captain.needa@star-destroyer.com,admiral.piett@star-destroyer.com',
          from: '"Email Output Acceptance Test Service" <moj-online@digital.justice.gov.uk>',
          email_body: '',
          include_attachments: false,
          include_pdf: true
        }
      end

      it 'sends an email with a csv attachement' do
        perform_job

        expect(email_output_service).to have_received(:execute) do |args|
          # (byebug) args
          # {:action=>{:kind=>"csv", :to=>"captain.needa@star-destroyer.com,admiral.piett@star-destroyer.com", :from=>"\"Email Output Acceptance Test Service\" <moj-online@digital.justice.gov.uk>", :subject=>"CSV Output Acceptance Test submission: fc242acb-c03f-439e-b41d-bec76fa0f032", :email_body=>"", :include_pdf=>true, :include_attachments=>false}, :attachments=>[#<Attachment:0x00007f5885ce2b08 @type=nil, @filename="e17f5560-5afa-4fdf-a14e-e68ed226f5ea-answers.csv", @url=nil, @mimetype="text/csv", @path="/tmp/20230511-1-tjn92h", @file=#<Tempfile:/tmp/20230511-1-tjn92h>>], :pdf_attachment=>nil}
          expect(args[:action]).to include(expected_action)
        end
      end
    end

    context 'when JSON API action' do
      # like v2:
      let(:encrypted_payload) do
        fixture = payload_fixture
        fixture['actions'] = fixture['actions'].select { |action| action['kind'] == 'json' }
        SubmissionEncryption.new(key:).encrypt(fixture)
      end
      let(:expected_action) do
        {
          kind: 'json',
          url: 'http://api-endpoint.com',
          data_url: 'deprecated field',
          encryption_key: 'fb730a667840d79c'
        }
      end

      # like v1:
      let(:json_webhook_service_spy) { instance_spy(JsonWebhookService) }

      before do
        allow(JsonWebhookService).to receive(:new).and_return(json_webhook_service_spy)
        perform_job
      end

      # like v1
      it 'passes the correct collaborators to the JsonWebhookService' do
        expect(JsonWebhookService).to have_received(:new) do |args|
          expect(args[:webhook_attachment_fetcher]).to be_an_instance_of(WebhookAttachmentService)
          expect(args[:webhook_destination_adapter]).to be_an_instance_of(Adapters::JweWebhookDestination)
        end
      end
      # like v2
      # it 'sends a output json' do
      #   perform_job

      #   expect(email_output_service).to have_received(:execute) do |args|
      #     byebug
      #     expect(args[:action]).to include(expected_action)
      #   end
      # end
    end
  end
end
