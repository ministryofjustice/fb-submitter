require 'rails_helper'

RSpec.describe Submission do
  describe '#decrypted_submission' do
    let(:key) { '48735f9a-f2a5-45d0-ba2e-03db2a99' }
    let(:encrypted_payload) do
      'vYOdDMInttFoyqEsUeTQeS/C4es=\n'
    end
    let(:decrypted_payload) do
      { sensitive: 'data' }
    end
    let(:submission) { described_class.create!(payload: encrypted_payload) }

    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('SUBMISSION_DECRYPTION_KEY').and_return(key)
    end

    it 'decrypts the payload' do
      expect(submission.decrypted_submission).to eq(decrypted_payload.stringify_keys)
    end
  end
end
