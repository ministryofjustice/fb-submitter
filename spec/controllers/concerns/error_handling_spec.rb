require 'rails_helper'

RSpec.describe 'Concerns::ErrorHandling' do
  let(:parsed_body) { JSON.parse(response.body) }

  controller do
    include Concerns::ErrorHandling

    def standard_error
      raise StandardError, 'boom!'
    end

    def record_not_found
      raise ActiveRecord::RecordNotFound, 'not found!'
    end
  end

  describe 'rescue from StandardError' do
    let(:is_prod_env) { false }

    before do
      routes.draw { get 'standard_error' => 'anonymous#standard_error' }

      allow(Rails.env).to receive(:production?).and_return(is_prod_env)
      allow(Sentry).to receive(:capture_exception)

      get :standard_error
    end

    it 'has status 500' do
      expect(response).to have_http_status(:internal_server_error)
    end

    describe 'the body' do
      it 'is valid JSON' do
        expect { parsed_body }.not_to raise_error
      end

      describe 'exception details' do
        context 'when running in a production environment' do
          let(:is_prod_env) { true }

          it 'has the details of the exception' do
            expect(parsed_body.fetch('errors').first.keys).to match_array(%w[message status title])
          end
        end

        context 'when running in a non-production environment' do
          it 'has the details of the exception' do
            expect(parsed_body.fetch('errors').first.keys).to match_array(%w[detail location message status title])
          end
        end
      end

      it 'has a message indicating the error' do
        expect(parsed_body.fetch('errors').first.fetch('title')).to eq(
          I18n.t(:title, scope: %i[error_messages internal_server_error])
        )
      end

      it 'reports the exception' do
        expect(Sentry).to have_received(:capture_exception).with(
          an_instance_of(StandardError)
        )
      end
    end
  end

  describe 'rescue from RecordNotFound' do
    before do
      routes.draw { get 'record_not_found' => 'anonymous#record_not_found' }
      allow(Sentry).to receive(:capture_exception)
      get :record_not_found
    end

    it 'has status 404' do
      expect(response).to have_http_status(:not_found)
    end

    describe 'the body' do
      it 'is valid JSON' do
        expect { parsed_body }.not_to raise_error
      end

      it 'has the details of the exception' do
        expect(parsed_body.fetch('errors').first.keys).to match_array(%w[status title])
      end

      it 'has a message indicating the error' do
        expect(parsed_body.fetch('errors').first.fetch('title')).to eq(
          I18n.t(:title, scope: %i[error_messages record_not_found])
        )
      end

      it 'does not report the exception' do
        expect(Sentry).not_to have_received(:capture_exception)
      end
    end
  end
end
