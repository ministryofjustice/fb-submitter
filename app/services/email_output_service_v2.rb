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
end
