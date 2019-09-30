require 'rails_helper'

RSpec.describe Email do
  describe 'validations' do
    describe 'to address' do
      subject do
        described_class.new(to: 'user@example.com',
                            template_name: 'email.generic')
      end

      context 'when invalid' do
        it 'is not valid' do
          subject.to = '1111'
          expect(subject).to_not be_valid

          subject.to = '@example.com'
          expect(subject).to_not be_valid

          subject.to = 'user@example'
          expect(subject).to_not be_valid

          subject.to = 'example.com'
          expect(subject).to_not be_valid
        end
      end

      context 'when valid' do
        it 'is valid' do
          expect(subject).to be_valid

          subject.to = 'user+test@example.com'
          expect(subject).to be_valid
        end
      end
    end
  end
end
