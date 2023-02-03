require 'rails_helper'

describe Adapters::AmazonSESAdapter do
  before do
    allow(Aws::SESV2::Client).to receive(:new).with(region: 'eu-west-1').and_return(stub_aws)
  end

  let(:stub_aws) do
    Aws::SESV2::Client.new(region: 'eu-west-1', stub_responses: true)
  end

  let(:default_from_address) { Adapters::AmazonSESAdapter::DEFAULT_FROM_ADDRESS }

  it 'returns the response given the correct params' do
    expect(described_class.send_mail(to: '', raw_message: '', from: '').to_h).to eq(message_id: 'OutboundMessageId')
  end

  context 'when sending email payload' do
    let(:to_address) { 'some_to_address@example.com' }
    let(:from_address) { 'Some Service <some_from_address@example.com>' }
    let(:email_body) { 'email body' }
    let(:opts) do
      {
        to: to_address,
        from: from_address,
        raw_message: double(to_s: email_body) # rubocop:disable RSpec/VerifiedDoubles
      }
    end
    let(:expected_payload) do
      {
        from_email_address: "Some Service <#{default_from_address}>",
        destination: {
          to_addresses: [to_address]
        },
        reply_to_addresses: expected_reply_to_addresses,
        content: {
          raw: {
            data: email_body
          }
        }
      }
    end

    # rubocop:disable RSpec/MessageSpies
    context 'when from address is different to moj forms default address' do
      let(:expected_reply_to_addresses) { [from_address] }

      it 'uses the supplied from address as the reply to address' do
        expect(stub_aws).to receive(:send_email).with(expected_payload)
        described_class.send_mail(opts)
      end
    end

    context 'when from address is the same as moj forms default address' do
      let(:from_address) { "Some Service <#{default_from_address}>" }
      let(:expected_reply_to_addresses) { [] }

      it 'does not set a reply to address' do
        expect(stub_aws).to receive(:send_email).with(expected_payload)
        described_class.send_mail(opts)
      end
    end
    # rubocop:enable RSpec/MessageSpies
  end
end
