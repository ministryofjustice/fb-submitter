require 'rails_helper'

describe SmsJob do
  subject(:job) { described_class.new }

  describe '#perform' do
    before do
      allow(Notifications::Client).to receive(:new).and_return(mock_client)
    end

    let(:mock_client) { instance_spy(Notifications::Client) }
    let(:to) { '07123456789' }
    let(:body) { 'Your code is 12345' }
    let(:message) do
      {
        to: to,
        body: body,
        template_name: 'sms.generic'
      }
    end
    let(:template_id) { 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' }

    let(:expected_sms_args) do
      {
        phone_number: to,
        template_id: template_id,
        personalisation: {
          body: body
        }
      }
    end

    it 'sends sms' do
      job.perform(message: message)
      expect(mock_client).to have_received(:send_sms).with(expected_sms_args)
    end

    context 'when extra personalisation' do
      let(:message) do
        {
          to: to,
          body: body,
          template_name: 'sms.generic',
          extra_personalisation: {
            token: 'my-token'
          }
        }
      end

      let(:expected_sms_args) do
        {
          phone_number: to,
          template_id: template_id,
          personalisation: {
            body: body,
            token: 'my-token'
          }
        }
      end

      it 'hands over data' do
        job.perform(message: message)
        expect(mock_client).to have_received(:send_sms).with(expected_sms_args)
      end
    end
  end
end
