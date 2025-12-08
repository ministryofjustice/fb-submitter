require 'rails_helper'
require 'ostruct'

RSpec.describe 'JWTAuthentication' do
  let(:service_token) { 'service-token' }
  let(:service_slug) { 'service-slug' }
  let(:request_id) { '12345' }
  let(:body) { response.body }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:payload) { {} }
  let(:headers) { { 'X-Request-Id' => request_id } }
  let(:encoded_private_key) { 'LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBM1NUQjJMZ2gwMllrdCtMcXo5bjY5MlNwV0xFdXNUR1hEMGlmWTBuRHpmbXF4MWVlCmx6MXh4cEpPTGV0ckxncW4zN2hNak5ZMC9uQUNjTWR1RUg5S1hycmFieFhYVGwxeVkyMStnbVd4NDlOZVlESW4KYmRtKzZzNUt2TGdVTk43WFZjZVA5UHVxWnlzeENWQTRUbm1MRURLZ2xTV2JVeWZ0QmVhVENKVkk2NFoxMmRNdApQYkFneFdBZmVTTGxiN0JQbHNIbS9IMEFBTCtuYmFPQ2t3dnJQSkRMVFZPek9XSE1vR2dzMnJ4akJIRC9OV05aCnNUVlFhbzRYd2hlYnVkaGx2TWlrRVczMldLZ0t1SEhXOHpkdlU4TWozM1RYK1picVhPaWtkRE54dHd2a1hGN0wKQTNZaDhMSTVHeWQ5cDZmMjdNZmxkZ1VJSFN4Y0pweTFKOEFQcXdJREFRQUJBb0lCQUU5ZjJTQVRmemlraWZ0aQp2RXRjZnlMN0EzbXRKd2c4dDI2cDcyT3czMUg0RWg4NHlOaWFHbE5ld2lialAvWW5wdmU2NitjRkg4SlBxK0NWCkJHRnhmdDBmampXZkRrZTNiTTVaUjdaQUVDaW8vay9pMEpveU5MK015ZkNRMWRmZ1FFUXV1L0gvdnJzSEdyT3cKRW5YQVZIUzg1enlCWWczbjM4QmxjVkw4V2s4R3FlMGxCUU5RSks5dSt5ckc5NEpoUTVoMTZubXlyQ0xpWkhSTAoyWS94MTdDL3BCN1VlUVFWeDZ4aVZSdVdmT1FoWlNmT2IzRHpsYldhc2owa2pTaHdWWDFQVG5sU0lxQXo5T3krClY5M013VFBtbVNOOGFiL0pGVlVBUzhtckM2elcxc0NjcFVUTFZHRVZBUFBJcWpjMmZFKzdLVGNjVDFzWkt0MWIKb2p1R2xSa0NnWUVBL2ZuK3VZcCtxSzdiQmxkUTZCSmNsNXpkR0xybXRrWFFZR096d2cvN21zd0NVdUM3UFpGYQpJV0xBSGM4QU85eDZvUFQ0SzFPNnQzYVBtMW8vUTR1S1N2NWNGK3EwaThMemVQM2JxdnowQXBXekdPVFdiMXg5CnNBRzNIOCtIT3JNS0NXVWl3bm5pUG1PMDNXUUY0dmFoWUd1WXYzSkNSNTYxanBJOFRkMkx6QmNDZ1lFQTN1ZkwKKzdqNGE2elVBOUNrak5wSnB2VkxyQk8ydUpiRHk5NXBpSzlCU3FIellQSEw3VVBWTExFaXRGWlNBWlRWRzFHMwpWbUNxMVoraXhCcTRST0t2VldyME1mSklsUlEvQXBQY3NwVXJjRTRPcnAxRkEyNjlLdXhhdnI5dmpLMCtIbWNRClEydWNRWWdUeWFXQlNZeW9laW04QWQ2UlpJRzVLQ25uTVlhNThZMENnWUVBNUp6VG5VLzlFdm5TVGJMck1QclcKUGVNRlllMWJIMWRZYW10VXM2cVBZSmVpdjlkcXM5RFN3SnFUTkVIUWhCSENrSC94bzQ2SzAvbjA2bkloNERzTApFTlpGTDRJbFltanBvRTlpSEZmMWpSNFRTS1UwSUttd3VXM1IyT0NGYVdFZjk3VUJ4T3pScWpjMTV0TFNPYXFuCk9KT2h1ekt1VnFtVjQrL2VPSGprRGFFQ2dZQUdMVFloeTRaV3RYdEtmOFdQZ1p6NDIyTTFhWFp1dHY3Rjcydk4KTmM0QlcydDdERGd5WXViTlRqcy85QVJodHRZUTQ3ckkwZlRwNW5xRUpKbG1qMEY4aEhJdjBCN2l3cVRjVld5UQpKa0lGNHFQVmd0WWV1anJUcmFqMkVDZnZKZjNLcWVCeGZkSGVudjZ0WDhDdFlSQnFFaTM3ZjBkWUdhQWYxTWxyClBlaDVJUUtCZ1FDbmN6YU8xcUx3VktyeUc4TzF5ZUhDSjQzT1h6SENwN3VnOE90aS9ScmhWZ08wSCtEdVpXUzUKSWhydHpUeU56MExyQTdibVFLTWZ4Y3k5Y29LOG9zZnVma1pZenJxM1ZFa0ViUCtjRWdLcGtlTDlaY2RSbXZ3WQozSTZkMUlOWVUwMldPSzhiRUJBNElJNGc0ak9ZcjJJUjFzb2lWZ0E2YnVya3E3QnMrUm41WFE9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=' }
  let(:encoded_public_key) { 'LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUEzU1RCMkxnaDAyWWt0K0xxejluNgo5MlNwV0xFdXNUR1hEMGlmWTBuRHpmbXF4MWVlbHoxeHhwSk9MZXRyTGdxbjM3aE1qTlkwL25BQ2NNZHVFSDlLClhycmFieFhYVGwxeVkyMStnbVd4NDlOZVlESW5iZG0rNnM1S3ZMZ1VOTjdYVmNlUDlQdXFaeXN4Q1ZBNFRubUwKRURLZ2xTV2JVeWZ0QmVhVENKVkk2NFoxMmRNdFBiQWd4V0FmZVNMbGI3QlBsc0htL0gwQUFMK25iYU9Da3d2cgpQSkRMVFZPek9XSE1vR2dzMnJ4akJIRC9OV05ac1RWUWFvNFh3aGVidWRobHZNaWtFVzMyV0tnS3VISFc4emR2ClU4TWozM1RYK1picVhPaWtkRE54dHd2a1hGN0xBM1loOExJNUd5ZDlwNmYyN01mbGRnVUlIU3hjSnB5MUo4QVAKcXdJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg==' }
  let(:fake_client) { OpenStruct.new(public_key: Base64.strict_decode64(encoded_public_key)) }

  controller do
    include ErrorHandling
    include JWTAuthentication

    def index
      head :ok
    end
  end

  before do
    allow(ServiceTokenService).to receive(:new).with(service_slug:, request_id:).and_return(fake_client)

    request.headers.merge!(headers)
    get :index, params: { service_slug: }
  end

  context 'with no x-access-token-v2 header' do
    it 'has status 401' do
      expect(response).to have_http_status(:unauthorized)
    end

    describe 'the body' do
      it 'is valid JSON' do
        expect { parsed_body }.not_to raise_error
      end

      describe 'the errors key' do
        it 'has a message indicating the header is not present' do
          expect(parsed_body.fetch('errors').first.fetch('title')).to eq(
            I18n.t(:title, scope: %i[error_messages token_not_present])
          )
        end
      end
    end
  end

  context 'with a header called x-access-token-v2' do
    let(:headers) do
      super().merge({
        'content-type' => 'application/json',
        'x-access-token-v2' => token
      })
    end
    let(:algorithm) { 'RS256' }
    let(:private_key) { OpenSSL::PKey::RSA.new(Base64.strict_decode64(encoded_private_key)) }

    context 'when valid' do
      let(:iat) { Time.zone.now.to_i }
      let(:token) do
        JWT.encode payload.merge({ iat: }), private_key, algorithm
      end

      it 'does not respond with an unauthorized or forbidden status' do
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context 'when not valid' do
      context 'when the timestamp is older than MAX_IAT_SKEW_SECONDS' do
        let(:iat) { Time.zone.now.to_i - 1.year }
        let(:token) do
          JWT.encode payload.merge({ iat: }), service_token, algorithm
        end
        let(:algorithm) { 'HS256' }

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
                I18n.t(:title, scope: %i[error_messages token_not_valid])
              )
            end
          end
        end
      end

      context 'when timestamp is > MAX_IAT_SKEW_SECONDS seconds in the future' do
        let(:headers) do
          super().merge({
            'content-type' => 'application/json',
            'x-access-token-v2' => token
          })
        end
        let(:algorithm) { 'RS256' }
        let(:private_key) { OpenSSL::PKey::RSA.new(Base64.strict_decode64(encoded_private_key)) }
        let(:iat) { Time.zone.now.to_i + (ENV['MAX_IAT_SKEW_SECONDS'].to_i + 1) }
        let(:token) do
          JWT.encode payload, private_key, algorithm
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
                I18n.t(:title, scope: %i[error_messages token_not_valid])
              )
            end
          end
        end
      end
    end
  end
end
