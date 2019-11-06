require_relative '../../app/services/generate_pdf_content'

describe GeneratePdfContent do
  subject(:pdf_service) { described_class.new(pdf_api_gateway: gateway, payload: payload) }

  let(:gateway) { instance_spy('Adapters::PdfApi', generate_pdf: 'some pdf contents') }
  let(:pdf_data) { { some: 'payload', submission_id: '123' } }
  let(:payload) { { submission: pdf_data } }

  context 'when requesting a pdf with a submission' do
    it 'calls generate_pdf on the gateway' do
      pdf_service.execute
      expect(gateway).to have_received(:generate_pdf).with(submission: pdf_data)
    end

    it 'returns an Attachment object' do
      result = pdf_service.execute
      expect(result.class).to eq(Attachment)
    end

    it 'assigns the correct info the the Attachment object' do
      result = pdf_service.execute
      expect(result.filename).to eq('123-answers.pdf')
      expect(result.mimetype).to eq('application/pdf')
      expect(File.open(result.path).read).to eq('some pdf contents')
    end
  end
end
