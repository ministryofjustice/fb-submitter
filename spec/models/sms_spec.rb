require 'rails_helper'

RSpec.describe Sms do
  describe 'validations' do
    describe 'to address' do
      subject do
        described_class.new(to: '07123456789',
                            template_name: 'sms.generic')
      end

      context 'when invalid' do
        it 'is not valid' do
          subject.to = '1111'
          expect(subject).to_not be_valid

          subject.to = 'qwertyuiopa'
          expect(subject).to_not be_valid

          subject.to = '111111111111111111111111'
          expect(subject).to_not be_valid
        end
      end

      context 'when valid' do
        it 'is valid' do
          expect(subject).to be_valid

          subject.to = '+4407123456789'
          expect(subject).to be_valid

          subject.to = '4407123456789'
          expect(subject).to be_valid

          subject.to = '+447123456789'
          expect(subject).to be_valid

          subject.to = '447123456789'
          expect(subject).to be_valid

          subject.to = '+447123456789'
          expect(subject).to be_valid

          subject.to = '447123456789'
          expect(subject).to be_valid

          subject.to = '+44 0712 3456789'
          expect(subject).to be_valid

          subject.to = '01632 960 001'
          expect(subject).to be_valid

          subject.to = '07700 900 982'
          expect(subject).to be_valid
        end
      end
    end
  end
end
