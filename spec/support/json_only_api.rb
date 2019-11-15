RSpec.shared_context 'when a JSON-only API' do |method_name, url|
  describe 'a json request' do
    let(:headers) do
      {
        'Content-type' => 'application/json'
      }
    end

    before do
      send(method_name, url, headers: headers)
    end

    it 'responds with the json content type' do
      expect(response.media_type).to eq('application/json')
    end

    it 'does not respond_with :unacceptable' do
      expect(response.status).not_to eq(:unacceptable)
    end
  end
end
