require 'rails_helper'

RSpec.describe RawMessage do
  before do
    allow_any_instance_of(File).to receive(:read).and_return('hello world')
  end

  describe 'attachment extension from mime type' do
    subject do
      described_class.new(
        body_parts: { 'text/html' => '' },
        attachments: [attachment]
      )
    end

    let(:attachment) do
      Attachment.new(
        type: nil,
        filename: 'some-file-name.jpg',
        url: nil,
        mimetype: 'application/pdf',
        path: file_fixture('hello_world.txt')
      )
    end

    it 'uses correct filename and extension' do
      expect(subject.to_s).to include('some-file-name.pdf')
    end

    context 'when filename does not have extension' do
      let(:attachment) do
        Attachment.new(
          type: nil,
          filename: 'some-file-name',
          url: nil,
          mimetype: 'application/pdf',
          path: file_fixture('hello_world.txt')
        )
      end

      it 'uses correct extension for given mimetype' do
        expect(subject.to_s).to include('some-file-name.pdf')
      end
    end
  end
end
