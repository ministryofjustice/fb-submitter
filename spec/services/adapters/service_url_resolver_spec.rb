require 'rails_helper'

describe Adapters::ServiceUrlResolver do
  subject { described_class.new(service_slug: service_slug, environment_slug: environment_slug) }

  let(:service_slug) { 'my-service' }
  let(:environment_slug) { 'dev' }

  describe '#resolve_uri_to_service' do
    context 'given a URI' do
      let(:uri) { URI.parse('/a/relative/path') }

      it 'resolves correctly' do
        expect(subject.resolve_uri_to_service(uri).to_s).to eql('http://my-service.formbuilder-services-dev:3000/a/relative/path')
      end
    end
  end

  describe '#ensure_absolute_url' do
    context 'given an absolute URL' do
      let(:url) { 'https://www.example.com/' }

      it 'returns the given URL unmodified' do
        expect(subject.ensure_absolute_url(url)).to eq(url)
      end
    end

    context 'given a relative URL' do
      let(:url) { '/a/relative/url' }

      it 'returns the resolved URL' do
        expect(subject.ensure_absolute_url(url)).to eq('http://my-service.formbuilder-services-dev:3000/a/relative/url')
      end
    end
  end
end
