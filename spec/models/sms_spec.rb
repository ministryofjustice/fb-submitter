require 'rails_helper'

RSpec.describe Sms do
  describe 'validations' do
    describe 'to address' do
      subject(:sms) do
        described_class.new(to: '07123456789',
                            template_name: 'sms.generic')
      end

      context 'when invalid' do
        invalid_numbers = [
          '1111',
          '+0',
          'qwertyuiopa',
          '111111111111111111111111'
        ]

        invalid_numbers.each do |value|
          it "#{value} is invalid" do
            sms.to = value
            expect(sms).not_to be_valid
          end
        end
      end

      context 'when valid' do
        valid_numbers = [
          '+4407123456789',
          '4407123456789',
          '+447123456789',
          '447123456789',
          '+447123456789',
          '447123456789',
          '+44 0712 3456789',
          '01632 960 001',
          '07700 900 982'
        ]

        valid_numbers.each do |value|
          it "#{value} is valid" do
            sms.to = value
            expect(sms).to be_valid
          end
        end
      end
    end
  end
end
