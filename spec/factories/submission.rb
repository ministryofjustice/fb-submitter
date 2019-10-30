FactoryBot.define do
  submission_id = SecureRandom.uuid

  factory :submission do
    status { Submission::STATUS[:queued] }
    service_slug { 'service-slug' }
    encrypted_user_id_and_token { 'some token' }
    transient do
      actions { [] }
      attachments { [] }
      submission { { 'submission_id' => submission_id } }
    end

    payload { { actions: actions, submission: submission, attachments: attachments } }

    trait :json do
      submission_details do
        [
          {
            type: 'json',
            url: 'https://my-custom-endpoint/ap/v1/foo',
            encryption_key: 'jdwjdwjwdhwhdh73',
            data_url: 'this-url-should-no-longer-be-called-or-used',
            submissionId: submission_id,
            user_answers: {
              first_name: 'bob',
              last_name: 'madly',
              submissionDate: 1_571_756_381_535,
              submissionId: SecureRandom.uuid
            },
            attachments: []
          }
        ]
      end
    end

    trait :email do
      submission_details do
        [
          {
            'from' => 'some.one@example.com',
            'to' => 'destination@example.com',
            'subject' => 'mail subject',
            'type' => 'email',
            'email_body' => 'some plain text',
            'attachments' => [
              {
                'type' => 'output',
                'mimetype' => 'application/pdf',
                'url' => '/api/submitter/pdf/default/guid1.pdf',
                'filename' => 'form1'
              },
              {
                'type' => 'output',
                'mimetype' => 'application/pdf',
                'url' => '/api/submitter/pdf/default/guid2.pdf',
                'filename' => 'form2'
              }
            ]
          }
        ]
      end
    end

    responses { {} }

    created_at { Time.current }
    updated_at { Time.current }
  end
end
