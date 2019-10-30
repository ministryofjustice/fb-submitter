require_relative '../../app/services/email_output_service'
require_relative '../../app/services/email_service'
require_relative '../../app/value_objects/attachment'

describe EmailOutputService do
  subject(:service) { described_class.new(emailer: email_service_mock) }

  let(:email_service_mock) { class_double(EmailService) }

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

  let(:attachments) do
    [
      Attachment.new(type: 'output', url: 'example.com/foo', mimetype: 'application/pdf', filename: 'form1', path: nil),
      Attachment.new(type: 'output', url: 'example.com/bar', mimetype: 'application/json', filename: 'form2', path: nil)
    ]
  end

  let(:pdf_attachment) do
    Attachment.new(type: 'output', url: nil, mimetype: 'application/pdf', filename: 'a generated pff', path: nil)
  end

  before do
    allow(email_service_mock).to receive(:send_mail)

    service.execute(action: email_action, attachments: attachments, pdf_attachment: pdf_attachment, submission_id: 'an-id-2323')
  end

  it 'execute sends an email' do
    expect(email_service_mock).to have_received(:send_mail).with(to: 'bob.admin@digital.justice.gov.uk',
                                                                 from: 'form-builder@digital.justice.gov.uk',
                                                                 subject: 'Complain about a court or tribunal submission {an-id-2323} [1/1]',
                                                                 body_parts: { 'text/plain': 'Please find an application attached' },
                                                                 attachments: []).once
  end

  context 'when a user uploaded attachments are required' do
    let(:include_attachments) { true }

    it 'sends a separate email for each attachment' do
      expect(email_service_mock).to have_received(:send_mail).with(hash_including(attachments: [attachments[0]])).once
      expect(email_service_mock).to have_received(:send_mail).with(hash_including(attachments: [attachments[1]])).once
    end

    it 'the subject is numbered by how many seperte emails there are' do
      expect(email_service_mock).to have_received(:send_mail).with(hash_including(subject: 'Complain about a court or tribunal submission {an-id-2323} [1/2]')).once
      expect(email_service_mock).to have_received(:send_mail).with(hash_including(subject: 'Complain about a court or tribunal submission {an-id-2323} [2/2]')).once
    end
  end

  context 'when a user answers pdf is needed' do
    let(:include_pdf) { true }

    it 'sends an email with the generated pdf as a attachment' do
      expect(email_service_mock).to have_received(:send_mail).with(hash_including(attachments: [pdf_attachment])).once
    end
  end

  context 'when both uploaded attachments and answers pdf are required' do
    let(:include_attachments) { true }
    let(:include_pdf) { true }

    it 'sends a separate email for each attachment' do
      expect(email_service_mock).to have_received(:send_mail).exactly(3).times
    end
  end
end
