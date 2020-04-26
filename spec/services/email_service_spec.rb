require 'rails_helper'

describe EmailService do
  subject { described_class.new(opts) }

  let(:opts) { { key: 'value', to: 'to@example.com' } }

  describe '.adapter' do
    it 'is Adapters::AmazonSESAdapter' do
      expect(subject.adapter).to eq(Adapters::AmazonSESAdapter)
    end

    context 'when overriding the email endpoint' do
      before do
        allow(ENV).to receive(:[]).with('EMAIL_ENDPOINT_OVERRIDE').and_return('http://some-custom-email-api.com')
      end

      it 'uses the mock email adapter' do
        expect(subject.adapter).to eq(Adapters::MockAmazonSESAdapter)
      end
    end
  end

  describe '.sanitised_params' do
    describe 'return value' do
      let(:return_value) { subject.sanitised_params(opts) }

      it 'is a hash' do
        expect(return_value).to be_a(Hash)
      end

      it 'has all the keys from the given opts' do
        opts.keys.each do |key|
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

  describe '.perform' do
    before do
      allow(Adapters::AmazonSESAdapter).to receive(:send_mail).and_return('send response')
    end

    it 'tells the adapter to send_mail, passing the opts' do
      subject.perform
      expect(subject.adapter).to have_received(:send_mail).with(hash_including(opts))
    end
  end
end
