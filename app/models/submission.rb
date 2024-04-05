class Submission < ActiveRecord::Base
  has_many :email_payloads, dependent: :destroy

  # V1 way of decrypting payload
  def decrypted_payload
    EncryptionService.new.decrypt(payload).to_h
  end

  # V2 way of decrypting payload
  def decrypted_submission
    SubmissionEncryption.new.decrypt(payload)
  end
end
