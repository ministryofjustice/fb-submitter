require 'tempfile'
require_relative '../value_objects/attachment'

class GeneratePdfContent
  def initialize(pdf_api_gateway:, payload:)
    @pdf_api_gateway = pdf_api_gateway
    @payload = payload
  end

  def execute
    pdf_contents = fetch_pdf
    tmp_pdf = generate_temp_file(pdf_contents)
    generate_attachment_object(tmp_pdf)
  end

  private

  def fetch_pdf
    pdf_api_gateway.generate_pdf(
      submission: payload.fetch(:submission)
    )
  end

  def generate_temp_file(pdf_contents)
    tmp_pdf = Tempfile.new
    tmp_pdf.binmode
    tmp_pdf.write(pdf_contents)
    tmp_pdf.rewind
    tmp_pdf
  end

  def generate_attachment_object(tmp_pdf)
    attachment = Attachment.new(
      filename: "#{payload[:submission][:submission_id]}-answers.pdf",
      mimetype: 'application/pdf',
      size: File.size(tmp_pdf.path)
    )
    attachment.file = tmp_pdf
    attachment
  end

  attr_reader :pdf_api_gateway, :payload
end
