require 'rails_helper'

describe TemplateMappingService::Sms do
  describe '#template_id_for_name' do
    before do
      stub_const('TemplateMappingService::Sms::ALL',
                 'sms.return.setup.mobile' => '54dcaad7-4967-431d-8606-72b0b80b5c6a')
    end

    context 'when template maps' do
      let(:name) { 'sms.return.setup.mobile' }
      let(:expected) { '54dcaad7-4967-431d-8606-72b0b80b5c6a' }

      it 'returns template' do
        expect(described_class.template_id_for_name(name)).to eql(expected)
      end
    end

    context 'when template does not map' do
      let(:name) { 'foo' }
      let(:expected) { '9153cfba-4808-4a1d-9b84-784500197651' }

      it 'raises error' do
        expect { described_class.template_id_for_name(name) }.to raise_error(TemplateMappingService::MissingTemplate)
      end
    end
  end
end
