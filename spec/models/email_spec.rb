require 'rails_helper'

RSpec.describe Email do
  describe 'validations' do
    describe 'to address' do
      subject(:email) do
        described_class.new(to: 'user@example.com',
                            template_name: 'email.generic')
      end

      context 'when invalid' do
        invalid_emails = [
          '1111',
          '@example.com',
          'user@example',
          'example.com'
        ]

        invalid_emails.each do |value|
          it "#{value} should be invalid" do
            email.to = value
            expect(email).not_to be_valid
          end
        end
      end

      context 'when valid' do
        value = 'user+test@example.com'

        it "#{value} should be valid" do
          email.to = value
          expect(email).to be_valid
        end
      end
    end
  end
end
