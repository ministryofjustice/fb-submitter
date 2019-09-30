require 'rails_helper'

describe TemplateMappingService::Email do
  describe '#template_id_for_name' do
    before do
      stub_const('TemplateMappingService::Email::ALL',
                 'email.return.setup.email.token' => '38f6a1cd-a810-4f59-8899-2c300236c5b4')
    end

    context 'when template maps' do
      let(:name) { 'email.return.setup.email.token' }
      let(:expected) { '38f6a1cd-a810-4f59-8899-2c300236c5b4' }

      it 'returns template' do
        expect(described_class.template_id_for_name(name)).to eql(expected)
      end
    end

    context 'when template does not map' do
      let(:name) { 'foo' }
      let(:expected) { '46a72b64-9541-4000-91a7-fa8a3fa10bf9' }

      it 'raises error' do
        expect { described_class.template_id_for_name(name) }.to raise_error(TemplateMappingService::MissingTemplate)
      end
    end
  end
end
