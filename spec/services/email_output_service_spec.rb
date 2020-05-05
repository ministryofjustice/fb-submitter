require_relative '../../app/services/email_output_service'
require_relative '../../app/services/email_service'
require_relative '../../app/value_objects/attachment'

describe EmailOutputService do
  let(:email_service_mock) { class_double(EmailService) }
  let(:download_service) { double() }
  let(:email_action) do
    {
      recipientType: 'team',
      type: 'email',
      from: 'form-builder@digital.justice.gov.uk',
      to: 'bob.admin@digital.justice.gov.uk',
      subject: 'Complain about a court or tribunal submission',
      email_body: 'Please find an application attached'
    }
  end

  before do
    allow(email_service_mock).to receive(:send_mail)
    allow(download_service).to receive(:download_in_parallel)
    subject.perform
  end

  context 'sending an email' do
    subject(:service) do
      described_class.new(
        action: email_action,
        emailer: email_service_mock,
        download_service: download_service,
        submission_id: 'an-id-2323',
        attachments: [],
        current_email: 1,
        number_of_emails: 1
      )
    end

    it 'execute sends an email' do
      expect(email_service_mock).to have_received(:send_mail).with(to: 'bob.admin@digital.justice.gov.uk',
                                                                  from: 'form-builder@digital.justice.gov.uk',
                                                                  subject: 'Complain about a court or tribunal submission {an-id-2323} [1/1]',
                                                                  body_parts: { 'text/plain': 'Please find an application attached' },
                                                                  attachments: []).once
    end
  end

  context 'when there are attachments' do
    subject(:service) do
      described_class.new(
        action: email_action,
        emailer: email_service_mock,
        download_service: download_service,
        submission_id: 'an-id-2323',
        attachments: ['foo', 'bar'],
        current_email: 1,
        number_of_emails: 1
      )
    end

    it 'should download those attachemnts' do
      expect(download_service).to have_received(:download_in_parallel).with(['foo', 'bar'])
    end
  end

  context 'when attachments is empty' do
    subject(:service) do
      described_class.new(
        action: email_action,
        emailer: email_service_mock,
        download_service: download_service,
        submission_id: 'an-id-2323',
        attachments: [],
        current_email: 1,
        number_of_emails: 1
      )
    end

    it 'should not attempt to download any attachments' do
      expect(download_service).not_to have_received(:download_in_parallel)
    end
  end

  context 'when action type is csv' do
    subject(:service) do
      described_class.new(
        action: email_action.merge(type: 'csv'),
        emailer: email_service_mock,
        download_service: download_service,
        submission_id: 'an-id-2323',
        attachments: ['anything'],
        current_email: 1,
        number_of_emails: 1
      )
    end

    it 'should not attempt to download any attachments' do
      expect(download_service).not_to have_received(:download_in_parallel)
      expect(email_service_mock).to have_received(:send_mail).with(hash_including(attachments: ['anything']))
    end
  end
end
