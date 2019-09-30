FactoryBot.define do
  factory :submission do
    status { Submission::STATUS[:queued] }
    service_slug { 'my-service' }
    encrypted_user_id_and_token { 'foo' }
    submission_type { nil }
    submission_details {
      {
        submissionId: SecureRandom.uuid,
        name: 'Mr Test'
      }
    }
    responses { {} }

    created_at { Time.current }
    updated_at { Time.current }
  end
end
