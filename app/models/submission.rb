class Submission < ActiveRecord::Base
  has_many :email_payloads, dependent: :destroy

  def decrypted_submission
    SubmissionEncryption.new.decrypt(payload)
  end
end
