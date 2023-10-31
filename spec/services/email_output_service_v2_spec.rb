require 'rails_helper'
require_relative '../../app/services/email_output_service_v2'
require_relative '../../app/services/email_service'
require_relative '../../app/services/attachment_generator'
require_relative '../../app/value_objects/attachment'

RSpec.describe EmailOutputServiceV2 do
  def match_payload(email_payloads, to, expected_filenames)
    expect(
      email_payloads.any? do |payload|
        payload.decrypted_attachments == expected_filenames.sort &&
        payload.decrypted_to == to
      end
    ).to be true
  end

  subject(:service) do
    described_class.new(
      emailer: email_service_mock,
      attachment_generator:,
      encryption_service:,
      submission_id:,
      payload_submission_id:
    )
  end

  let(:submission_id) { create(:submission).id }
  let(:payload_submission_id) { 'an-id-2323' }

  let(:email_service_mock) { class_double(EmailService) }
  let(:raw_message_mock) { class_double(V2::RawMessage) }
  let(:attachment_generator) { AttachmentGenerator.new }
  let(:encryption_service) { EncryptionService.new }

  let(:email_action) do
    {
      recipientType: 'team',
      type: 'email',
      from: 'form-builder@digital.justice.gov.uk',
      to: 'bob.admin@digital.justice.gov.uk',
      subject: 'Complain about a court or tribunal submission',
      email_body: 'Please find an application attached',
      user_answers: 'My answer is that I like chocolate',
      include_pdf:,
      include_attachments:
    }
  end

  let(:include_pdf) { false }
  let(:include_attachments) { false }

  let(:upload1) { build(:attachment) }
  let(:upload2) { build(:attachment) }
  let(:upload3) { build(:attachment) }

  let(:attachments) do
    [upload1, upload2, upload3]
  end

  let(:pdf_attachment) { build(:attachment, mimetype: 'application/pdf', url: nil) }

  let(:execution_payload) do
    {
      action: email_action,
      attachments:,
      pdf_attachment:
    }
  end
  let(:send_email_payload) do
    {
      to: 'bob.admin@digital.justice.gov.uk',
      from: 'form-builder@digital.justice.gov.uk',
      subject: 'Complain about a court or tribunal submission {an-id-2323} [1/1]',
      body_parts: {
        'text/plain': 'Please find an application attachedMy answer is that I like chocolate',
        'text/html': 'Please find an application attachedMy answer is that I like chocolate'
      },
      attachments: [],
      raw_message: V2::RawMessage
    }
  end

  before do
    allow(upload1).to receive(:size).and_return(1234)
    allow(upload2).to receive(:size).and_return(5678)
    allow(upload3).to receive(:size).and_return(8_999_999)
    allow(pdf_attachment).to receive(:size).and_return(7777)
  end

  context 'when email sending succeeds' do
    before do
      allow(email_service_mock).to receive(:send_mail)
      service.execute(**execution_payload)
    end

    it 'execute sends an email' do
      expect(email_service_mock).to have_received(:send_mail).with(send_email_payload).once
    end

    context 'when a user uploaded attachments are required but not answers pdf' do
      let(:include_attachments) { true }
      let(:first_email_attachments) { [upload1, upload2] }
      let(:second_email_attachments) { [upload3] }

      it 'groups attachments into emails up to maximum limit' do
        expect(email_service_mock).to have_received(:send_mail).exactly(2).times
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(attachments: first_email_attachments)).once
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(attachments: second_email_attachments)).once
      end

      it 'the subject is numbered by how many separate emails there are' do
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(subject: 'Complain about a court or tribunal submission {an-id-2323} [1/2]')).once
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(subject: 'Complain about a court or tribunal submission {an-id-2323} [2/2]')).once
      end

      it 'creates the required email payload records' do
        email_payloads = EmailPayload.all

        expect(email_payloads.count).to eq(2)
        email_payloads.each { |payload| expect(payload.succeeded_at).not_to be_nil }
        match_payload(email_payloads, 'bob.admin@digital.justice.gov.uk', first_email_attachments.map(&:filename).sort)
        match_payload(email_payloads, 'bob.admin@digital.justice.gov.uk', second_email_attachments.map(&:filename).sort)
      end
    end

    context 'when a user answers pdf is needed but not uploaded attachments' do
      let(:include_pdf) { true }

      it 'sends an email with the generated pdf as a attachment' do
        expect(email_service_mock).to have_received(:send_mail).exactly(1).times
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(attachments: [pdf_attachment])).once
      end

      it 'the subject is numbered [1/1] as there will be a single email' do
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(subject: 'Complain about a court or tribunal submission {an-id-2323} [1/1]')).once
      end
    end

    context 'when both uploaded attachments and answers pdf are required' do
      let(:include_attachments) { true }
      let(:include_pdf) { true }

      it 'groups attachments per email, pdf submission first remainder based on attachment size, ' do
        first_email_attachments = [pdf_attachment, upload1, upload2]
        second_email_attachments = [upload3]

        expect(email_service_mock).to have_received(:send_mail).exactly(2).times
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(attachments: first_email_attachments)).once
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(attachments: second_email_attachments)).once
      end
    end
  end

  # rubocop:disable RSpec/ExampleLength
  context 'when email sending fails' do
    let(:include_attachments) { true }
    let(:first_email_attachments) { [upload1, upload2] }
    let(:second_email_attachments) { [upload3] }
    let(:first_payload) do
      send_email_payload.merge(
        subject: 'Complain about a court or tribunal submission {an-id-2323} [1/2]',
        body_parts: {
          'text/html': 'Please find an application attachedMy answer is that I like chocolate',
          'text/plain': 'Please find an application attachedMy answer is that I like chocolate'
        },
        attachments: first_email_attachments
      )
    end

    let(:second_payload) do
      send_email_payload.merge(
        subject: 'Complain about a court or tribunal submission {an-id-2323} [2/2]',
        body_parts: {
            'text/html': 'Please find an application attached',
            'text/plain': 'Please find an application attached'
          },
        attachments: second_email_attachments
      )
    end

    it 'only retries emails that did not previously succeed' do
      allow(email_service_mock).to receive(:send_mail).with(first_payload)
      allow(email_service_mock).to receive(:send_mail).with(second_payload).and_raise(Aws::SESV2::Errors::MessageRejected.new({}, 'it was the day my grandmother exploded'))

      expect { service.execute(**execution_payload) }.to raise_error(Aws::SESV2::Errors::MessageRejected)

      email_payloads = EmailPayload.all
      expect(email_payloads.count).to eq(2)
      email_payloads.each do |payload|
        if payload.decrypted_attachments == second_email_attachments.map(&:filename).sort
          expect(payload.succeeded_at).to be_nil
        end
      end

      allow(email_service_mock).to receive(:send_mail)
      expect(email_service_mock).not_to receive(:send_mail).with(first_payload) # rubocop:disable  RSpec/MessageSpies

      service.execute(**execution_payload)

      email_payloads = EmailPayload.all
      expect(email_payloads.count).to eq(2)
      email_payloads.each do |payload|
        if payload.decrypted_attachments == second_email_attachments.map(&:filename).sort
          expect(payload.succeeded_at).not_to be_nil
        end
      end
    end

    it 'does not care about the ordering of the attachments when retrying' do
      allow(email_service_mock).to receive(:send_mail).with(first_payload).and_raise(Aws::SESV2::Errors::MessageRejected.new({}, 'all children, except one, grow up'))
      allow(email_service_mock).to receive(:send_mail).with(second_payload)
      expect { service.execute(**execution_payload) }.to raise_error(Aws::SESV2::Errors::MessageRejected)

      allow(email_service_mock).to receive(:send_mail)
      service.execute(**execution_payload.merge(attachments: [upload3, upload2, upload1]))

      email_payloads = EmailPayload.all
      expect(email_payloads.count).to eq(2)
      email_payloads.each do |payload|
        if payload.decrypted_attachments == second_email_attachments.map(&:filename).sort
          expect(payload.succeeded_at).not_to be_nil
        end
      end
    end
  end

  context 'when there are multiple service output emails' do
    let(:first_service) do
      described_class.new(
        emailer: email_service_mock,
        attachment_generator: AttachmentGenerator.new,
        encryption_service:,
        submission_id:,
        payload_submission_id:
      )
    end
    let(:second_service) do
      described_class.new(
        emailer: email_service_mock,
        attachment_generator: AttachmentGenerator.new,
        encryption_service:,
        submission_id:,
        payload_submission_id:
      )
    end
    let(:first_email_attachments) { [pdf_attachment, upload1, upload2] }
    let(:second_email_attachments) { [upload3] }
    let(:include_attachments) { true }
    let(:include_pdf) { true }
    let(:second_email_action) { email_action.merge(to: 'robert.admin@digital.justice.gov.uk') }
    let(:second_execution_payload) { execution_payload.merge(action: second_email_action) }

    context 'when email are sent successfully' do
      before do
        allow(email_service_mock).to receive(:send_mail)
        first_service.execute(**execution_payload)
        second_service.execute(**second_execution_payload)
      end

      it 'will send emails to the necessary recipients' do
        expect(email_service_mock).to have_received(:send_mail).exactly(4).times
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(to: 'bob.admin@digital.justice.gov.uk')).twice
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(to: 'robert.admin@digital.justice.gov.uk')).twice
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(subject: 'Complain about a court or tribunal submission {an-id-2323} [1/2]')).twice
        expect(email_service_mock).to have_received(:send_mail).with(hash_including(subject: 'Complain about a court or tribunal submission {an-id-2323} [2/2]')).twice
      end

      it 'will creates email payloads to the necessary recipients with the correct attachments' do
        email_payloads = EmailPayload.all
        expect(email_payloads.count).to eq(4)
        ['bob.admin@digital.justice.gov.uk', 'robert.admin@digital.justice.gov.uk'].each do |to|
          match_payload(email_payloads, to, first_email_attachments.map(&:filename).sort)
          match_payload(email_payloads, to, second_email_attachments.map(&:filename).sort)
        end
      end
    end

    context 'when some emails fail to be sent' do
      let(:third_service) do
        described_class.new(
          emailer: email_service_mock,
          attachment_generator: AttachmentGenerator.new,
          encryption_service:,
          submission_id:,
          payload_submission_id:
        )
      end
      let(:fourth_service) do
        described_class.new(
          emailer: email_service_mock,
          attachment_generator: AttachmentGenerator.new,
          encryption_service:,
          submission_id:,
          payload_submission_id:
        )
      end
      let(:first_payload) do
        send_email_payload.merge(
          subject: 'Complain about a court or tribunal submission {an-id-2323} [1/2]',
          body_parts: {
            'text/html': 'Please find an application attachedMy answer is that I like chocolate',
            'text/plain': 'Please find an application attachedMy answer is that I like chocolate'
          },
          attachments: first_email_attachments
        )
      end
      let(:second_payload) do
        send_email_payload.merge(
          subject: 'Complain about a court or tribunal submission {an-id-2323} [2/2]',
          body_parts: {
            'text/html': 'Please find an application attached',
            'text/plain': 'Please find an application attached'
          },
          attachments: second_email_attachments
        )
      end
      let(:third_payload) do
        send_email_payload.merge(
          to: 'robert.admin@digital.justice.gov.uk',
          subject: 'Complain about a court or tribunal submission {an-id-2323} [1/2]',
          body_parts: {
            'text/html': 'Please find an application attachedMy answer is that I like chocolate',
            'text/plain': 'Please find an application attachedMy answer is that I like chocolate'
          },
          attachments: first_email_attachments
        )
      end
      let(:fourth_payload) do
        send_email_payload.merge(
          to: 'robert.admin@digital.justice.gov.uk',
          subject: 'Complain about a court or tribunal submission {an-id-2323} [2/2]',
          body_parts: {
            'text/html': 'Please find an application attached',
            'text/plain': 'Please find an application attached'
          },
          attachments: second_email_attachments
        )
      end

      it 'only retries emails to recipients that did not previously succeed' do
        allow(email_service_mock).to receive(:send_mail).with(first_payload)
        allow(email_service_mock).to receive(:send_mail).with(second_payload)
        allow(email_service_mock).to receive(:send_mail).with(third_payload)
        allow(email_service_mock).to receive(:send_mail).with(fourth_payload).and_raise(Aws::SESV2::Errors::MessageRejected.new({}, 'it was a pleasure to burn'))

        first_service.execute(**execution_payload)
        expect { second_service.execute(**second_execution_payload) }.to raise_error(Aws::SESV2::Errors::MessageRejected)

        email_payloads = EmailPayload.all
        expect(email_payloads.count).to eq(4)

        email_payloads.each do |payload|
          if payload.decrypted_to == 'robert.admin@digital.justice.gov.uk' && payload.decrypted_attachments == second_email_attachments.map(&:filename).sort
            expect(payload.succeeded_at).to be_nil
          end
        end

        # rubocop:disable  RSpec/MessageSpies
        allow(email_service_mock).to receive(:send_mail)
        expect(email_service_mock).not_to receive(:send_mail).with(first_payload)
        expect(email_service_mock).not_to receive(:send_mail).with(second_payload)
        expect(email_service_mock).not_to receive(:send_mail).with(third_payload)
        # rubocop:enable  RSpec/MessageSpies

        third_service.execute(**execution_payload)
        fourth_service.execute(**second_execution_payload)

        email_payloads = EmailPayload.all
        expect(email_payloads.count).to eq(4)
        email_payloads.each do |payload|
          if payload.decrypted_to == 'robert.admin@digital.justice.gov.uk' && payload.decrypted_attachments == second_email_attachments.map(&:filename).sort
            expect(payload.succeeded_at).not_to be_nil
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
