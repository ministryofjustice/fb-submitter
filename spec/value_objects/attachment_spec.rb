require_relative '../../app/value_objects/attachment'
require 'tempfile'

RSpec.describe Attachment do
  subject(:attachment_instance) { described_class.new(type: 'output', url: nil, filename: 'something.pdf', mimetype: 'application/pdf', path:) }

  let(:tempfile) { Tempfile.new }
  let(:path) { 'path/to/file' }

  it 'can hold pdf file' do
    attachment = attachment_instance.file = tempfile
    expect(attachment.path).to eq(tempfile.path)
  end

  describe '#size' do
    before do
      allow(File).to receive(:size).with(path).and_return(123)
    end

    it 'returns the file size' do
      expect(attachment_instance.size).to eq(123)
    end
  end
end
