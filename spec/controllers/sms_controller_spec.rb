require 'rails_helper'

describe SmsController do
  before do
    request.env['CONTENT_TYPE'] = 'application/json'
    allow_any_instance_of(ApplicationController).to receive(:verify_token!)
  end

  let(:json_hash) do
    {
      message: {
        to: '07123456789',
        body: 'form saved at https://example.com',
        template_name: 'sms.generic'
      }
    }
  end

  describe 'POST #create' do
    it 'enqueues job' do
      expect {
        post :create, body: json_hash.to_json, format: :json
      }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.by(1)
    end

    it 'returns 201' do
      post :create, body: json_hash.to_json, format: :json
      expect(response).to be_created
    end

    it 'returns empty json object in body' do
      post :create, body: json_hash.to_json, format: :json
      expect(response.body).to eql('{}')
    end

    context 'when extra personalisation' do
      let(:json_hash) do
        {
          message: {
            to: '07123456789',
            body: 'form saved at https://example.com',
            template_name: 'sms.generic',
            extra_personalisation: {
              code: '12345'
            }
          }
        }
      end

      it 'adds data to job' do
        post :create, body: json_hash.to_json, format: :json

        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.last[:args][0]['message']['extra_personalisation']['code']).to eql('12345')
      end
    end

    context 'when no template found for template_name' do
      let(:json_hash) do
        {
          message: {
            to: '07123456789',
            body: 'form saved at https://example.com',
            template_name: 'foo'
          }
        }
      end

      it 'returns 400' do
        post :create, body: json_hash.to_json, format: :json
        expect(response).to be_bad_request
      end

      it 'returns an error message' do
        post :create, body: json_hash.to_json, format: :json
        expect(JSON.parse(response.body)['name']).to eql('bad-request.invalid-parameters')
      end
    end
  end
end
