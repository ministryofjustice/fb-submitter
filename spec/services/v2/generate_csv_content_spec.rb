require 'rails_helper'

RSpec.describe V2::GenerateCsvContent do
  subject(:generate_csv_content) { described_class.new(payload_service:) }

  let(:payload_service) do
    V2::SubmissionPayloadService.new(payload)
  end
  let(:submission_at) { Time.zone.now.iso8601(3) }
  let(:submission_id) { SecureRandom.uuid }

  let(:meta) do
    { 'meta' => { 'submission_at' => submission_at } }
  end
  let(:payload) do
    {
      'service' => { 'id' => submission_id },
      'pages' => [
        {
          'heading' => 'Your name',
          'answers' => [
            {
              'field_id' => 'name_text_1',
              'answer' => 'Stormtrooper'
            },
            {
              'field_id' => 'name_text_2',
              'answer' => 'FN-some-last-name'
            }
          ]
        },
        {
          'heading' => '',
          'answers' => [
            {
              'field_id' => 'your-email-address_text_1',
              'answer' => 'fb-acceptance-tests@digital.justice.gov.uk'
            }
          ]
        },
        {
          'heading' => 'Your life history',
          'answers' => [
            {
              'field_id' => 'life-history_textarea_1',
              'answer' => "Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro.\n\r\nDe carne lumbering animata corpora quaeritis.\n\r\nSummus brains sit, morbo vel maleficia?"
            }
          ]
        },
        {
          'heading' => 'Your postal address',
          'answers' => [
            {
              'field_id' => 'postal-address_address_1',
              'answer' => {
                'address_line_one' => '1 road',
                'address_line_two' => '',
                'city' => "ruby\r\ntown",
                'county' => '',
                'postcode' => '99 999',
                'country' => 'ruby land'
              }
            }
          ]
        }
      ]
    }.merge(meta)
  end

  context 'when requesting a csv with a submission' do
    let(:expected_column_0) do
      %w[
        submission_id
        submission_at
        name_text_1
        name_text_2
        your-email-address_text_1
        life-history_textarea_1
        postal-address_address_1/address_line_one
        postal-address_address_1/address_line_two
        postal-address_address_1/city
        postal-address_address_1/county
        postal-address_address_1/postcode
        postal-address_address_1/country
      ]
    end
    let(:expected_column_1) do
      [
        payload_service.submission_id,
        submission_at,
        'Stormtrooper',
        'FN-some-last-name',
        'fb-acceptance-tests@digital.justice.gov.uk',
        'Zombie ipsum reversus ab viral inferno, nam rick grimes malum cerebro. De carne lumbering animata corpora quaeritis. Summus brains sit, morbo vel maleficia?',
        '1 road',
        '',
        'ruby town',
        '',
        '99 999',
        'ruby land'
      ]
    end

    it 'returns an Attachment object' do
      result = generate_csv_content.execute
      expect(result.class).to eq(Attachment)
    end

    it 'uses the submission id in the file name' do
      result = generate_csv_content.execute

      expect(result.filename).to eq("#{payload_service.submission_id}-answers.csv")
      expect(result.mimetype).to eq('text/csv')
    end

    it 'adds the correct info to the attachment object' do
      result = generate_csv_content.execute
      file_contents = File.open(result.path).read
      csv = CSV.new(file_contents).read

      expect(csv[0]).to eq(expected_column_0)
      expect(csv[1]).to eq(expected_column_1)
    end
  end

  context 'when reference number is present' do
    let(:reference_number) { 'some-reference-number' }
    let(:meta) do
      { 'meta' => {
        'submission_at' => submission_at,
        'reference_number' => reference_number
      } }
    end

    it 'does not add the submission id' do
      result = generate_csv_content.execute
      file_contents = File.open(result.path).read
      csv = CSV.new(file_contents).read

      expect(csv[0]).not_to include('submission_id')
      expect(csv[1]).not_to include(submission_id)
    end

    it 'adds the reference number' do
      result = generate_csv_content.execute
      file_contents = File.open(result.path).read
      csv = CSV.new(file_contents).read

      expect(csv[0]).to include('reference_number')
      expect(csv[1]).to include(reference_number)
    end

    it 'uses the reference number in the file name' do
      result = generate_csv_content.execute

      expect(result.filename).to eq("#{reference_number}-answers.csv")
      expect(result.mimetype).to eq('text/csv')
    end
  end
end
