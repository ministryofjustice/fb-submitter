require 'swagger_helper'

RSpec.describe 'sms' do
  before do
    allow_any_instance_of(ApplicationController).to receive(:disable_jwt?).and_return(true)
  end

  path '/sms' do
    post 'send an sms' do
      consumes 'application/json'

      parameter name: :json, in: :body, required: true, schema: {
        type: :object,
        properties: {
          service_slug: { type: :string, required: true, example: 'my-form' },
          message: {
            type: :object,
            properties: {
              to: { type: :string, required: true, example: 'user@example.com' },
              body: { type: :string, required: true, example: 'body goes here' },
              template_name: { type: :string, required: true, example: 'sms.generic' },
              extra_personalisation: {
                type: :object,
                required: false,
                example: '{ "token": "token-goes-here" }'
              }
            }
          }
        }
      }

      response '201', 'sms job created' do
        let(:json) do
          {
            service_slug: 'service-slug',
            message: {
              to: '07123456789',
              body: 'body goes here',
              template_name: 'sms.generic'
            }
          }
        end

        examples 'application/json' => {}

        run_test!
      end
    end
  end
end
