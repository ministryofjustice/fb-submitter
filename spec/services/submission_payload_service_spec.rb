require_relative '../../app/services/submission_payload_service'

RSpec.describe SubmissionPayloadService do
  subject(:service) { described_class.new(payload) }

  let(:payload) do
    { 'actions' =>
        [{ 'recipientType' => 'team',
           'type' => 'email',
           'from' =>
             '"Complain about a court or tribunal" <form-builder@digital.justice.gov.uk>',
           'to' => 'bob.admin@digital.justice.gov.uk',
           'subject' => 'Complain about a court or tribunal submission',
           'email_body' => 'Please find an application attached',
           'include_pdf' => true,
           'include_attachments' => true }],
      'submission' =>
        { 'submission_id' => '8f5dd756-df07-40e7-afc7-682cdf490264',
          'pdf_heading' => 'Complain about a court or tribunal',
          'sections' =>
            [{ 'heading' => 'Your name', 'summary_heading' => '', 'questions' => [] },
             { 'heading' => '',
               'summary_heading' => '',
               'questions' =>
                 [{ 'label' => 'First name', 'answer' => 'Bob', 'key' => 'first_name' },
                  { 'label' => 'Last name', 'answer' => 'Smith', 'key' => 'last_name' }] },
             { 'heading' => '',
               'summary_heading' => '',
               'questions' =>
                 [{ 'label' => 'Can we contact you about your complaint by email?',
                    'answer' => 'Yes',
                    'key' => 'has-email' },
                  { 'label' => 'Your email address',
                    'answer' => 'bob.smith@digital.justice.gov.uk',
                    'key' => 'email_address' },
                  { 'label' => 'Your complaint',
                    'answer' => 'Some complaint details',
                    'key' => 'complaint_details' },
                  { 'label' =>
                      'Would you like to send any documents as part of your complaint?',
                    'answer' => 'No',
                    'key' => 'has-complaint-documents' }] }] },
      'attachments' => [1, 2, 3] }
  end

  let(:expected_user_answers_map) do
    {
      'first_name' => 'Bob',
      'last_name' => 'Smith',
      'has-email' => 'Yes',
      'email_address' => 'bob.smith@digital.justice.gov.uk',
      'complaint_details' => 'Some complaint details',
      'has-complaint-documents' => 'No'
    }
  end
  let(:expected_actions) do
    [
      {
        'recipientType' => 'team',
        'type' => 'email',
        'from' =>
         '"Complain about a court or tribunal" <form-builder@digital.justice.gov.uk>',
        'to' => 'bob.admin@digital.justice.gov.uk',
        'subject' => 'Complain about a court or tribunal submission',
        'email_body' => 'Please find an application attached',
        'include_pdf' => true,
        'include_attachments' => true
      }
    ]
  end
  let(:expected_submission) do
    {
      'pdf_heading' => 'Complain about a court or tribunal',
      'sections' => [{ 'heading' => 'Your name', 'questions' => [], 'summary_heading' => '' }, { 'heading' => '', 'questions' => [{ 'answer' => 'Bob', 'key' => 'first_name', 'label' => 'First name' }, { 'answer' => 'Smith', 'key' => 'last_name', 'label' => 'Last name' }], 'summary_heading' => '' }, { 'heading' => '', 'questions' => [{ 'answer' => 'Yes', 'key' => 'has-email', 'label' => 'Can we contact you about your complaint by email?' }, { 'answer' => 'bob.smith@digital.justice.gov.uk', 'key' => 'email_address', 'label' => 'Your email address' }, { 'answer' => 'Some complaint details', 'key' => 'complaint_details', 'label' => 'Your complaint' }, { 'answer' => 'No', 'key' => 'has-complaint-documents', 'label' => 'Would you like to send any documents as part of your complaint?' }], 'summary_heading' => '' }],
      'submission_id' => '8f5dd756-df07-40e7-afc7-682cdf490264'
    }
  end

  it 'returns a array of attachments objects' do
    expect(service.attachments).to eq([1, 2, 3])
  end

  it 'returns all actions' do
    expect(service.actions).to eq(expected_actions)
  end

  it 'returns the user submission answers' do
    expect(service.submission).to eq(expected_submission)
  end

  it 'returns a map of question ids to user answers' do
    expect(service.user_answers_map).to eq(expected_user_answers_map)
  end
end
