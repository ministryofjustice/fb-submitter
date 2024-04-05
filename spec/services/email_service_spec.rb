require 'rails_helper'

describe EmailService do
  describe '.adapter' do
    it 'is Adapters::AmazonSESAdapter' do
      expect(described_class.adapter).to eq(Adapters::AmazonSESAdapter)
    end

    context 'when overriding the email endpoint' do
      before do
        allow(ENV).to receive(:[]).with('EMAIL_ENDPOINT_OVERRIDE').and_return('http://some-custom-email-api.com')
      end

      it 'uses the mock email adapter' do
        expect(described_class.adapter).to eq(Adapters::MockAmazonSESAdapter)
      end
    end
  end

  describe '.sanitised_params' do
    let(:opts) { { key: 'value', to: 'to@example.com', raw_message: RawMessage } }

    describe 'return value' do
      let(:return_value) { described_class.sanitised_params(opts) }

      it 'is a hash' do
        expect(return_value).to be_a(Hash)
      end

      it 'has all the keys from the given opts' do
        opts.each_key do |key|
          expect(return_value.keys).to include(key)
        end
      end

      context 'when the OVERRIDE_EMAIL_TO env var is set' do
        before do
          allow(ENV).to receive(:[]).with('OVERRIDE_EMAIL_TO').and_return('overridden_to')
        end

        it 'sets :to to the value of OVERRIDE_EMAIL_TO' do
          expect(return_value[:to]).to eq('overridden_to')
        end

        describe 'the :raw_message param' do
          let(:raw_message) { return_value[:raw_message] }

          it 'has .to set to the OVERRIDE_EMAIL_TO' do
            expect(raw_message.to).to eq('overridden_to')
          end
        end
      end

      context 'when OVERRIDE_EMAIL_TO is not set' do
        it 'does not change :to' do
          expect(return_value[:to]).to eq(opts[:to])
        end

        describe 'the :raw_message param' do
          let(:raw_message) { return_value[:raw_message] }

          it 'has .to set to the given :to' do
            expect(raw_message.to).to eq(opts[:to])
          end
        end
      end
    end
  end

  describe '.send_mail' do
    let(:opts) { { key: 'value', to: 'to@example.com', raw_message: RawMessage } }
    let(:sanitised_params) { { key: 'sanitised value' } }

    before do
      allow(Adapters::AmazonSESAdapter).to receive(:send_mail).and_return('send response')
      allow(described_class).to receive(:sanitised_params).with(opts).and_return(sanitised_params)
    end

    it 'sanitises the params' do
      described_class.send_mail(opts)
      expect(described_class).to have_received(:sanitised_params).with(opts)
    end

    it 'tells the adapter to send_mail, passing the sanitised_params' do
      described_class.send_mail(opts)
      expect(described_class.adapter).to have_received(:send_mail).with(sanitised_params)
    end
  end
end
