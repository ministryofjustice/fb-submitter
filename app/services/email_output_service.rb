class EmailOutputService
  def initialize(action:, emailer:, download_service:, submission_id:, attachments:,
                 current_email:, number_of_emails:)
    @action = action
    @emailer = emailer
    @download_service = download_service
    @submission_id = submission_id
    @attachments = attachments
    @current_email = current_email
    @number_of_emails = number_of_emails
  end

  def perform
    if attachments.empty? || action.fetch(:type) == 'csv'
      send_email(attachments)
    else
      email_attachments = download_service.download_in_parallel(attachments)
      send_email(email_attachments)
    end
  end

  private

  def send_email(attachments)
    emailer.send_mail(
      from: action.fetch(:from),
      to: action.fetch(:to),
      subject: subject,
      body_parts: email_body_parts,
      attachments: attachments
    )
  end

  def subject
    "#{action.fetch(:subject)} {#{submission_id}} [#{current_email}/#{number_of_emails}]"
  end

  def email_body_parts
    {
      'text/plain': action.fetch(:email_body)
    }
  end

  attr_reader :action, :emailer, :download_service, :submission_id, :attachments,
              :current_email, :number_of_emails
end
