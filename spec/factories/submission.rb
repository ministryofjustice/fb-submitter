FactoryBot.define do
  factory :submission do
    status { Submission::STATUS[:queued] }
    service_slug { 'my-service' }
    encrypted_user_id_and_token { 'foo' }
    submission_details do
      {
        submissionId: SecureRandom.uuid,
        name: 'Mr Test'
      }
    end
    responses { {} }

    created_at { Time.current }
    updated_at { Time.current }
  end
end
