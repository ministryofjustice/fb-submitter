class EmailOutputService
  def initialize(emailer:)
    @emailer = emailer
  end

  def execute(submission_id:, action:, attachments:, pdf_attachment:)
    email_attachments = generate_attachments(action: action, attachments: attachments, pdf_attachment: pdf_attachment)

    if email_attachments.empty?
      send_single_email(
        action: action,
        subject: subject(subject: action.fetch(:subject), submission_id: submission_id)
      )
    else
      send_emails_with_attachments(action, email_attachments, submission_id: submission_id)
    end
  end

  private

  def generate_attachments(action:, attachments:, pdf_attachment:)
    email_attachments = []

    if action.fetch(:include_attachments) == true
      email_attachments = email_attachments.concat attachments
    end
    if action.fetch(:include_pdf) == true
      email_attachments.prepend(pdf_attachment)
    end
    email_attachments
  end

  def send_emails_with_attachments(action, email_attachments, submission_id:)
    email_attachments.each_with_index do |email_attachment, index|
      send_single_email(
        action: action,
        attachments: [email_attachment],
        subject: subject(
          subject: action.fetch(:subject),
          current_email: index + 1,
          number_of_emails: email_attachments.size,
          submission_id: submission_id
        )
      )
    end
  end

  def send_single_email(subject:, action:, attachments: [])
    emailer.send_mail(
      from: action.fetch(:from),
      to: action.fetch(:to),
      subject: subject,
      body_parts: email_body_parts(action.fetch(:email_body)),
      attachments: attachments
    )
  end

  def subject(submission_id:, subject:, current_email: 1, number_of_emails: 1)
    "#{subject} {#{submission_id}} [#{current_email}/#{number_of_emails}]"
  end

  def email_body_parts(email_body)
    {
      'text/plain': email_body
    }
  end

  attr_reader :emailer
end
