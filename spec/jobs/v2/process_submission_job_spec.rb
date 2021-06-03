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
      create(:submission, payload: encrypted_payload, access_token: access_token)
    end
    let(:encrypted_payload) do
      SubmissionEncryption.new(key: key).encrypt(JSON.parse(
                                                   File.read(
                                                     Rails.root.join('spec/fixtures/payloads/valid_submission.json')
                                                   )
                                                 ))
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
    let(:generated_pdf_content) do
      "I'm one with the Force. The Force is with me.\n"
    end
    let(:expected_action) do
      {
        subject: 'Email Output Acceptance Test submission: fc242acb-c03f-439e-b41d-bec76fa0f032',
        to: 'captain.needa@star-destroyer.com,admiral.piett@star-destroyer.com'
      }
    end

    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('SUBMISSION_DECRYPTION_KEY').and_return(key)
      allow(EmailOutputService).to receive(:new).and_return(email_output_service)

      stub_request(:post, 'http://pdf-generator.com/v1/pdfs')
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

    it 'sends the email with subject' do
      perform_job

      expect(email_output_service).to have_received(:execute) do |args|
        expect(args[:action]).to include(expected_action)
      end
    end
  end
end
