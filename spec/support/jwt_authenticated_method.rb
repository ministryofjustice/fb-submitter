RSpec.shared_examples 'a JWT-authenticated method' do |method, url, payload|
  let(:body) { response.body }
  let(:parsed_body) do
    JSON.parse(response.body.to_s)
  end
  let(:headers) do
    {
      'content-type' => 'application/json'
    }
  end
  let(:service_token) { 'ServiceToken' }
  before do
    allow_any_instance_of(ApplicationController).to receive(:get_service_token).and_return(service_token)
    send(method, url, headers: headers)
  end

  context 'with no x-access-token header' do
    it 'has status 401' do
      expect(response).to have_http_status(:unauthorized)
    end

    describe 'the body' do
      let(:body) { response.body }

      it 'is valid JSON' do
        expect { parsed_body }.not_to raise_error
      end

      describe 'the errors key' do
        it 'has a message indicating the header is not present' do
          expect(parsed_body.fetch('errors').first.fetch('title')).to eq(
            I18n.t(:title, scope: [:error_messages, :token_not_present])
          )
        end
      end
    end
  end

  context 'with a header called x-access-token' do
    let(:headers) do
      {
        'content-type' => 'application/json',
        'x-access-token' => token
      }
    end
    let(:service_token) { 'ServiceToken' }
    let(:algorithm) { 'HS256' }

    context 'when valid' do
      let(:iat) { Time.current.to_i }
      let(:token) do
        JWT.encode payload.merge(iat: iat), service_token, algorithm
      end

      it 'does not respond with an unauthorized or forbidden status' do
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context 'when not valid' do
      let(:token) { 'invalid token' }

      context 'when the timestamp is older than MAX_IAT_SKEW_SECONDS' do
        let(:iat) { Time.current.to_i - (ENV['MAX_IAT_SKEW_SECONDS'].to_i + 1) }
        let(:token) do
          JWT.encode payload.merge(iat: iat), service_token, algorithm
        end

        it 'has status 403' do
          expect(response).to have_http_status(:forbidden)
        end

        describe 'the body' do
          it 'is valid JSON' do
            expect { parsed_body }.not_to raise_error
          end

          describe 'the errors key' do
            it 'has a message indicating the token is invalid' do
              expect(parsed_body.fetch('errors').first.fetch('title')).to eq(
                I18n.t(:title, scope: [:error_messages, :token_not_valid])
              )
            end
          end
        end
      end

      context 'when timestamp is > MAX_IAT_SKEW_SECONDS seconds in the future' do
        let(:iat) { Time.current.to_i + (ENV['MAX_IAT_SKEW_SECONDS'].to_i + 1) }
        let(:token) do
          JWT.encode payload, service_token, algorithm
        end

        it 'has status 403' do
          expect(response.status).to eq(403)
        end

        describe 'the body' do
          it 'is valid JSON' do
            expect { parsed_body }.not_to raise_error
          end

          describe 'the errors key' do
            it 'has a message indicating the token is invalid' do
              expect(parsed_body.fetch('errors').first.fetch('title')).to eq(
                I18n.t(:title, scope: [:error_messages, :token_not_valid])
              )
            end
          end
        end
      end
    end
  end
end
