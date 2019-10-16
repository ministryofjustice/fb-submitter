class SaveTempPdf
  def initialize(generate_pdf_content_service:, tmp_file_gateway:)
    @generate_pdf_content_service = generate_pdf_content_service
    @tmp_file_gateway = tmp_file_gateway
  end

  def execute(file_name:)
    tmp_pdf = tmp_file_gateway.new([file_name, '.pdf'])
    pdf_contents = generate_pdf_content_service.execute

    tmp_pdf.binmode
    tmp_pdf.write(pdf_contents)
    tmp_pdf.rewind

    tmp_pdf
  end

  private

  attr_reader :generate_pdf_content_service, :tmp_file_gateway
end
