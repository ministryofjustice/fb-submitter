require_relative '../../app/value_objects/attachment'
require 'tempfile'

RSpec.describe Attachment do
  subject(:attachment_instance) { described_class.new(type: 'output', url: nil, filename: 'somthing.pdf', mimetype: 'application/pdf', path: nil) }

  let(:tempfile) { Tempfile.new }

  it 'can hold pdf file' do
    attachment = attachment_instance.file = tempfile
    expect(attachment.path).to eq(tempfile.path)
  end
end
