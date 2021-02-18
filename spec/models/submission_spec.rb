require 'rails_helper'

RSpec.describe Submission do
  describe '#decrypted_payload' do
    let(:encrypted_payload) do
      'GmEKcG/J7NXDuJzwjvBrpOCp79b2KXt9DzvP--S3c+ifLNDezwVL3D--CNbzzIDKJXjDlxu7OvWQ6Q=='
    end

    let(:decrypted_payload) do
      { sensitive: 'data' }
    end

    let(:submission) { described_class.create!(payload: encrypted_payload) }

    it 'decrypts the payload' do
      expect(submission.decrypted_payload).to eq(decrypted_payload)
    end
  end

  describe '#decrypted_submission' do
    let(:key) { '48735f9a-f2a5-45d0-ba2e-03db2a99' }
    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('SUBMISSION_DECRYPTION_KEY').and_return(key)
    end

    let(:encrypted_payload) do
      'vYOdDMInttFoyqEsUeTQeS/C4es=\n'
    end

    let(:decrypted_payload) do
      { sensitive: 'data' }
    end

    let(:submission) { described_class.create!(payload: encrypted_payload) }

    it 'decrypts the payload' do
      expect(submission.decrypted_submission).to eq(decrypted_payload.stringify_keys)
    end
  end
end
