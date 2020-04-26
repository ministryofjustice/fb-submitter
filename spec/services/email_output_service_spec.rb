require 'rails_helper'
require_relative '../../app/services/email_output_service'
require_relative '../../app/services/email_service'
require_relative '../../app/services/attachment_generator'
require_relative '../../app/value_objects/attachment'

describe EmailOutputService do
  def execute_email_output
    service.execute(
      action: email_action,
      attachments: attachments,
      pdf_attachment: pdf_attachment,
      submission_id: 'an-id-2323'
    )
  end

  subject(:service) do
    described_class.new(
      emailer: emailer,
      attachment_generator: attachment_generator
    )
  end

  let(:emailer) { EmailService }
  let(:email_service) { object_double(EmailService.new, perform: nil) }
  let(:attachment_generator) { AttachmentGenerator.new }

  let(:email_action) do
    {
      recipientType: 'team',
      type: 'email',
      from: 'form-builder@digital.justice.gov.uk',
      to: 'bob.admin@digital.justice.gov.uk',
      subject: 'Complain about a court or tribunal submission',
      email_body: 'Please find an application attached',
      include_pdf: include_pdf,
      include_attachments: include_attachments
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

  let(:expected_params) do
    {
      from: 'form-builder@digital.justice.gov.uk',
      to: 'bob.admin@digital.justice.gov.uk',
      subject: 'Complain about a court or tribunal submission {an-id-2323} [1/1]',
      body_parts: { 'text/plain': 'Please find an application attached' },
      attachments: []
    }
  end

  let(:pdf_attachment) { build(:attachment, mimetype: 'application/pdf', url: nil) }

  before do
    Delayed::Worker.delay_jobs = false
    allow(upload1).to receive(:size).and_return(1234)
    allow(upload2).to receive(:size).and_return(5678)
    allow(upload3).to receive(:size).and_return(8_999_999)
    allow(pdf_attachment).to receive(:size).and_return(7777)
  end

  after do
    Delayed::Worker.delay_jobs = true
  end

  # rubocop:disable RSpec/MessageSpies
  it 'enqueues a job and sends an email' do
    expect(Delayed::Job).to receive(:enqueue).with(email_service)
    expect(emailer).to receive(:new).with(expected_params).and_return(email_service)

    execute_email_output
  end

  context 'when a user uploaded attachments are required but not answers pdf' do
    let(:include_attachments) { true }

    it 'groups attachments into emails up to maximum limit' do
      first_email_attachments = [upload1, upload2]
      second_email_attachments = [upload3]

      expect(emailer).to receive(:new).with(hash_including(attachments: first_email_attachments)).and_return(email_service)
      expect(emailer).to receive(:new).with(hash_including(attachments: second_email_attachments)).and_return(email_service)

      execute_email_output
    end

    it 'the subject is numbered by how many separate emails there are' do
      expect(emailer).to receive(:new).with(hash_including(subject: 'Complain about a court or tribunal submission {an-id-2323} [1/2]')).and_return(email_service)
      expect(emailer).to receive(:new).with(hash_including(subject: 'Complain about a court or tribunal submission {an-id-2323} [2/2]')).and_return(email_service)

      execute_email_output
    end
  end

  context 'when a user answers pdf is needed but not uploaded attachments' do
    let(:include_pdf) { true }

    it 'sends an email with the generated pdf as a attachment' do
      expect(emailer).to receive(:new).with(hash_including(attachments: [pdf_attachment])).and_return(email_service)

      execute_email_output
    end

    it 'the subject is numbered [1/1] as there will be a single email' do
      expect(emailer).to receive(:new).with(hash_including(subject: 'Complain about a court or tribunal submission {an-id-2323} [1/1]')).and_return(email_service)

      execute_email_output
    end
  end

  context 'when both uploaded attachments and answers pdf are required' do
    let(:include_attachments) { true }
    let(:include_pdf) { true }

    it 'groups attachments per email, pdf submission first remainder based on attachment size, ' do
      first_email_attachments = [pdf_attachment, upload1, upload2]
      second_email_attachments = [upload3]

      expect(emailer).to receive(:new).with(hash_including(attachments: first_email_attachments)).and_return(email_service)
      expect(emailer).to receive(:new).with(hash_including(attachments: second_email_attachments)).and_return(email_service)

      execute_email_output
    end
  end
  # rubocop:enable RSpec/MessageSpies
end
