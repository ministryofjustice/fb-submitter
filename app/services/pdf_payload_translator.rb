class PdfPayloadTranslator
  attr_reader :decrypted_submission

  def initialize(decrypted_submission)
    @decrypted_submission = ActiveSupport::HashWithIndifferentAccess.new(
      decrypted_submission
    )
  end

  def to_h
    {
      submission: {
        submission_id: decrypted_submission[:submission_id],
        reference_number: meta[:reference_number],
        pdf_heading: meta[:pdf_heading],
        pdf_subheading: meta[:pdf_subheading],
        sections: decrypted_submission[:pages].map do |page|
          {
            heading: page[:heading],
            summary_heading: '',
            questions: page[:answers].map do |user_answer|
              {
                label: user_answer[:field_name],
                human_value: human_value(user_answer[:answer])
              }
            end
          }
        end
      }.compact
    }
  end

  private

  def meta
    decrypted_submission[:meta]
  end

  def human_value(answer)
    if answer.is_a?(Array)
      answer.join("\r\n")
    elsif answer.is_a?(Hash)
      answer.values.compact_blank.join(', ')
    else
      answer
    end
  end
end
