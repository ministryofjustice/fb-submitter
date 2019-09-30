require 'rails_helper'

describe EmailJob do
  subject(:job) { described_class.new }

  describe '#perform' do
    before do
      allow(Notifications::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:send_email)
    end

    let(:mock_client) { instance_double(Notifications::Client) }
    let(:to) { 'user@example.com' }
    let(:email_subject) { 'subject goes here' }
    let(:body) { 'saved form at https://example.com' }
    let(:message) do
      {
        to: to,
        subject: email_subject,
        body: body,
        template_name: 'email.generic'
      }
    end
    let(:template_id) { '46a72b64-9541-4000-91a7-fa8a3fa10bf9' }

    let(:expected_email_args) do
      {
        email_address: to,
        template_id: template_id,
        personalisation: {
          subject: email_subject,
          body: body
        }
      }
    end

    it 'sends email' do
      job.perform(message: message)
      expect(mock_client).to have_received(:send_email).with(expected_email_args)
    end

    context 'when extra personalisation' do
      let(:message) do
        {
          to: to,
          subject: email_subject,
          body: body,
          template_name: 'email.generic',
          extra_personalisation: {
            token: 'my-token'
          }
        }
      end

      let(:expected_email_args) do
        {
          email_address: to,
          template_id: template_id,
          personalisation: {
            subject: email_subject,
            body: body,
            token: 'my-token'
          }
        }
      end

      it 'hands over data' do
        job.perform(message: message)
        expect(mock_client).to have_received(:send_email).with(expected_email_args)
      end
    end
  end
end
