FactoryBot.define do
  submission_id = SecureRandom.uuid

  factory :submission do
    service_slug { 'service-slug' }
    encrypted_user_id_and_token { 'some token' }
    transient do
      actions { [] }
      attachments { [] }
      submission do
        {
          'submission_id' => submission_id,
          'pdf_heading' => 'Application against a refusal of criminal legal aid on interests of justice grounds',
          'pdf_subheading' => 'IOJ',
          'sections' => [
            {
              'heading' => 'Case details',
              'summary_heading' => '',
              'questions' => []
            },
            {
              'heading' => '',
              'summary_heading' => '',
              'questions' => [
                {
                  'label' => 'Unique submission number (USN)',
                  'answer' => '1234567',
                  'key' => 'usn'
                }
              ]
            },
            {
              'heading' => 'MAAT number',
              'summary_heading' => '',
              'questions' => []
            },
            {
              'heading' => '',
              'summary_heading' => '',
              'questions' => [
                {
                  'label' => 'MAAT number',
                  'answer' => '6123456',
                  'key' => 'maat[1]'
                }
              ]
            },
            {
              'heading' => 'Defendant’s details',
              'summary_heading' => '',
              'questions' => []
            },
            {
              'heading' => '',
              'summary_heading' => '',
              'questions' => [
                {
                  'label' => 'Full name',
                  'answer' => 'john doe',
                  'key' => 'fullname'
                },
                {
                  'label' => 'Date of birth',
                  'answer' => '1 January 1990',
                  'key' => 'dob'
                }
              ]
            },
            {
              'heading' => 'Solicitor’s details',
              'summary_heading' => '',
              'questions' => []
            },
            {
              'heading' => '',
              'summary_heading' => '',
              'questions' => [
                {
                  'label' => 'Full name',
                  'answer' => 'Mr Solicitor',
                  'key' => 'solicitor_fullname'
                },
                {
                  'label' => 'Firm',
                  'answer' => 'Pearson',
                  'key' => 'firm'
                },
                {
                  'label' => 'Email address',
                  'answer' => 'info@solicitor.co.uk',
                  'key' => 'solicitor_email'
                },
                {
                  'label' => 'Legal aid provider account number',
                  'answer' => '1A234B',
                  'key' => 'lapan'
                }
              ]
            },
            {
              'heading' => 'Offence',
              'summary_heading' => '',
              'questions' => []
            },
            {
              'heading' => '',
              'summary_heading' => '',
              'questions' => [
                {
                  'label' => 'Offence type',
                  'answer' => 'Grand theft auto',
                  'key' => 'offence[1].type'
                },
                {
                  'label' => 'Date of offence',
                  'answer' => '1 January 1990',
                  'key' => 'offence[1].date'
                },
                {
                  'label' => 'Reasons for appeal',
                  'answer' => 'A genuine reason',
                  'key' => 'offence[1].reasons'
                }
              ]
            },
            {
              'heading' => '',
              'summary_heading' => '',
              'questions' => []
            },
            {
              'heading' => '',
              'summary_heading' => '',
              'questions' => [
                {
                  'label' => 'Attach any documentation that supports your appeal',
                  'answer' => 'an-image.jpg',
                  'key' => 'documentation'
                }
              ]
            }
          ]
        }
      end
    end

    payload do
      EncryptionService.new.encrypt(
        actions: actions, submission: submission, attachments: attachments
      )
    end

    trait :json do
      actions do
        [
          {
            type: 'json',
            url: 'https://my-custom-endpoint/ap/v1/foo',
            encryption_key: 'jdwjdwjwdhwhdh73'
          }
        ]
      end
    end

    trait :email do
      actions do
        [
          {
            'from' => 'some.one@example.com',
            'to' => 'destination@example.com',
            'subject' => 'mail subject',
            'type' => 'email',
            'email_body' => 'some plain text'
          }
        ]
      end
    end

    created_at { Time.current }
    updated_at { Time.current }
  end
end
