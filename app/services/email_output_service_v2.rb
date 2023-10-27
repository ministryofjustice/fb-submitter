class EmailOutputServiceV2 < BaseEmailOutputService
  def raw_message
    V2::RawMessage
  end

  def email_body_parts(email_body)
    {
      'text/plain': strip_tags(email_body),
      'text/html': email_body
    }
  end

  def send_emails_with_attachments(action, email_attachments)
    email_attachments.each_with_index do |attachments, index|
      send_single_email(
        action:,
        attachments:,
        subject: subject(
          subject: action.fetch(:subject),
          current_email: index + 1,
          number_of_emails: email_attachments.size
        ),
        email_body: email_body_for_index(action, index)
      )
    end
  end

  def send_single_email(subject:, action:, attachments: [], email_body:)
    to = action.fetch(:to)
    email_payload = find_or_create_email_payload(to, attachments)

    if email_payload.succeeded_at.nil?
      emailer.send_mail(
        from: action.fetch(:from),
        to:,
        subject:,
        body_parts: email_body_parts(:email_body),
        attachments:,
        raw_message:
      )

      email_payload.update!(succeeded_at: Time.zone.now)
    end
  end

  def email_body_for_index(action, index)
    email_body = action.fetch(:email_body)
    user_answers = action.fetch(:user_answers)
    if index == 0
      email_body +  user_answers
    else
      email_body
    end
  end


end
