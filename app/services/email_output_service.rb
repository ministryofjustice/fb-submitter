class EmailOutputService
  include ActionView::Helpers::SanitizeHelper

  def initialize(emailer:, attachment_generator:, encryption_service:, submission_id:,
                 payload_submission_id:)
    @emailer = emailer
    @attachment_generator = attachment_generator
    @encryption_service = encryption_service
    @submission_id = submission_id
    @payload_submission_id = payload_submission_id
  end

  def execute(action:, attachments:, pdf_attachment:)
    attachment_generator.execute(
      action:,
      attachments:,
      pdf_attachment:
    )

    if attachment_generator.sorted_attachments.empty?
      send_single_email(
        action:,
        subject: subject(subject: action.fetch(:subject)),
        email_body: email_body_for_index(action)
      )
    else
      send_emails_with_attachments(
        action,
        attachment_generator.sorted_attachments
      )
    end
  end

  private

  def send_emails_with_attachments(action, email_attachments)
    email_attachments.each_with_index do |attachments, index|
      send_single_email(
        subject: subject(
          subject: action.fetch(:subject),
          current_email: index + 1,
          number_of_emails: email_attachments.size
        ),
        action:,
        email_body: email_body_for_index(action, index),
        attachments:
      )
    end
  end

  def send_single_email(subject:, action:, email_body:, attachments: [])
    to = action.fetch(:to)
    email_payload = find_or_create_email_payload(to, attachments)

    if email_payload.succeeded_at.nil?
      emailer.send_mail(
        from: action.fetch(:from),
        to:,
        subject:,
        body_parts: email_body_parts(email_body),
        attachments:,
        variant: action[:variant],
        raw_message: RawMessage
      )

      email_payload.update!(succeeded_at: Time.zone.now)
    end
  end

  def subject(subject:, current_email: 1, number_of_emails: 1)
    "#{subject} {#{payload_submission_id}} [#{current_email}/#{number_of_emails}]"
  end

  def find_or_create_email_payload(to, attachments)
    filenames = attachments.map(&:filename).sort
    email_payload = EmailPayload.where(submission_id:)
                                .find do |payload|
      payload.decrypted_to == to &&
        payload.decrypted_attachments == filenames
    end

    email_payload || EmailPayload.create!(submission_id:,
                                          to: encryption_service.encrypt(to),
                                          attachments: encryption_service.encrypt(filenames))
  end

  def email_body_parts(email_body)
    {
      'text/plain': strip_tags(email_body),
      'text/html': email_body
    }
  end

  def email_body_for_index(action, index = 0)
    email_body = action.fetch(:email_body)
    # Some emails would not have any user answers. Like for save & return and csv.
    user_answers = action.fetch(:user_answers, '')
    if index.zero?
      email_body + user_answers
    else
      email_body
    end
  end

  attr_reader :emailer, :attachment_generator, :encryption_service, :submission_id,
              :payload_submission_id
end
