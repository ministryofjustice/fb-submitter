require 'rails_helper'

RSpec.describe V2::SubmissionPayloadService do
  subject(:payload_service) { described_class.new(payload) }

  let(:submission_id) { SecureRandom.uuid }
  let(:submission_at) { Time.zone.now.iso8601(3) }
  let(:payload) do
    {
      'submission_id' => submission_id,
      'meta' => {
        'pdf_heading' => 'Submission for new-runner-acceptance-tests',
        'pdf_subheading' => 'Submission subheading for new-runner-acceptance-tests',
        'submission_at' => submission_at
      },
      'service' => {
        'id' => SecureRandom.uuid,
        'slug' => 'new-runner-acceptance-tests',
        'name' => 'new runner acceptance tests'
      },
      'actions' => [
        {
          'kind' => 'email',
          'to' => 'fb-acceptance-tests@digital.justice.gov.uk',
          'from' => 'moj-forms@digital.justice.gov.uk',
          'subject' => 'Submission from new-runner-acceptance-tests',
          'email_body' => 'Please find attached a submission sent from new-runner-acceptance-tests',
          'include_pdf' => true,
          'include_attachments' => true
        },
        {
          'kind' => 'csv',
          'to' => 'fb-acceptance-tests@digital.justice.gov.uk',
          'from' => 'moj-forms@digital.justice.gov.uk',
          'subject' => 'Submission from new-runner-acceptance-tests',
          'email_body' => '',
          'include_pdf' => true,
          'include_attachments' => false
        },
        {
          'kind' => 'json',
          'url' => 'http://api-endpoint.com',
          'key': 'fb730a667840d79c'
        }
      ],
      'pages' => [
        {
          'heading' => 'Your name',
          'answers' => [
            {
              'field_id' => 'name_text_1',
              'field_name' => 'First name',
              'answer' => 'Stormtrooper'
            },
            {
              'field_id' => 'name_text_2',
              'field_name' => 'Last name',
              'answer' => 'FN-b0046eb3-37ff-400d-85f8-8bbb5c11183b'
            }
          ]
        },
        {
          'heading' => '',
          'answers' => [
            {
              'field_id' => 'your-email-address_text_1',
              'field_name' => 'Your email address',
              'answer' => 'fb-acceptance-tests@digital.justice.gov.uk'
            }
          ]
        }
      ],
      'attachments' => [
        {
          'url ' => 'http://the-filestore-url-for-attachment',
          'filename' => 'hello_world.txt',
          'mimetype' => 'text/plain'
        }
      ]
    }
  end

  describe '#submission_id' do
    it 'returns the correct submission id' do
      expect(payload_service.submission_id).to eq(submission_id)
    end
  end

  describe '#submission_at' do
    context 'when submission_at is present' do
      it 'returns the correctly formatted submission_at' do
        expect(payload_service.submission_at).to eq(submission_at)
      end
    end
  end

  describe '#user_answers' do
    let(:expected_user_answers) do
      {
        'name_text_1' => 'Stormtrooper',
        'name_text_2' => 'FN-b0046eb3-37ff-400d-85f8-8bbb5c11183b',
        'your-email-address_text_1' => 'fb-acceptance-tests@digital.justice.gov.uk'
      }
    end

    it 'returns the correctly formatted user answers' do
      expect(payload_service.user_answers).to eq(expected_user_answers)
    end
  end

  describe '#reference_number' do
    context 'when reference number does not exists in the payload' do
      it 'returns nil' do
        expect(payload_service.reference_number).to be_nil
      end
    end

    context 'when reference number exists in the payload' do
      let(:reference_number) { 'some-reference-number' }
      let(:payload) do
        { 'meta' => { 'reference_number' => reference_number } }
      end

      it 'returns the reference number' do
        expect(payload_service.reference_number).to eq(reference_number)
      end
    end
  end

  describe '#attachments' do
    let(:expected_attachments) do
      [
        {
          'url ' => 'http://the-filestore-url-for-attachment',
          'filename' => 'hello_world.txt',
          'mimetype' => 'text/plain'
        }
      ]
    end

    it 'returns a array of attachments objects' do
      expect(payload_service.attachments).to eq(expected_attachments)
    end
  end
end
