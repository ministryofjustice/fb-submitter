require 'rails_helper'
require 'webmock/rspec'

describe 'V2 Submissions endpoint', type: :request do
  describe 'a POST request' do
    let(:fb_jwt_auth) { instance_double(Fb::Jwt::Auth, verify!: true) }
    let(:access_token) { 'an-jwt-access-token' }
    let(:headers) do
      {
        'Content-type' => 'application/json',
        'Accept' => 'application/json',
        'X-Request-Id' => request_id,
        'Authorization': "Bearer #{access_token}"
      }
    end
    let(:request_id) { '12345' }
    let(:service_slug) { 'mos-eisley' }
    let(:encrypted_user_id_and_token) { '4df5ab180993404877562a03601a1137' }
    let(:url) { '/v2/submissions' }
    let(:pdf_file_content) { 'apology accepted, captain needa' }
    let(:post_request) { post url, params: params.to_json, headers: }
    let(:submission_decryption_key) { SecureRandom.uuid[0..31] }
    let(:response_body) { JSON.parse(response.body) }

    before do
      allow(Fb::Jwt::Auth).to receive(:new).and_return(fb_jwt_auth)
      Delayed::Worker.delay_jobs = false

      stub_request(
        :get,
        'http://fake_service_token_cache_root_url/service/mos-eisley'
      ).to_return(status: 200, body: { token: '123' }.to_json)
      stub_request(
        :post,
        'http://pdf-generator.com/v1/pdfs'
      ).to_return(status: 200, body: pdf_file_content)
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[])
        .with('SUBMISSION_DECRYPTION_KEY')
        .and_return(submission_decryption_key)
    end

    after do
      Delayed::Worker.delay_jobs = true
    end

    include_context 'when a JSON-only API', :post, '/v2/submissions'

    context 'with a valid token' do
      let(:valid_submission_payload) do
        JSON.parse(
          File.read(
            Rails.root.join('spec/fixtures/payloads/valid_submission.json')
          )
        )
      end

      before do
        allow(fb_jwt_auth).to receive(:verify!).and_return(true)
      end

      context 'with valid submission payload' do
        let(:params) do
          {
            encrypted_submission: SubmissionEncryption.new(
              key: submission_decryption_key
            ).encrypt(valid_submission_payload),
            service_slug:,
            encrypted_user_id_and_token:
          }
        end

        let(:submission) { Submission.last }
        let(:submission_id) { submission.id }

        it 'returns status 201' do
          post_request
          expect(response_body).to eq({})
          expect(response).to have_http_status(:created)
        end

        it 'creates a submission record' do
          expect { post_request }.to change(Submission, :count).by(1)
        end

        it 'creates a V2 Job to be processed asynchronously' do
          process_submission_job = class_spy(V2::ProcessSubmissionJob).as_stubbed_const
          post_request

          expect(
            process_submission_job
          ).to have_received(:perform_later).with(submission_id:, request_id:)
        end

        context 'when saving the submission in the database' do
          # rubocop:disable RSpec/ExpectInHook
          before do
            post_request
            expect(submission).not_to be_nil
          end
          # rubocop:enable RSpec/ExpectInHook

          it 'encrypts the submission in the database' do
            expect(submission.payload).not_to be_nil
            expect(submission.decrypted_submission).to eq(valid_submission_payload)
          end

          it 'saves the submission access token' do
            expect(submission.access_token).to eq(access_token)
          end

          it 'saves submission service slug' do
            expect(submission.service_slug).to eq(service_slug)
          end

          it 'saves submisstion encrypted user id and token' do
            expect(submission.encrypted_user_id_and_token).to eq(
              encrypted_user_id_and_token
            )
          end
        end
      end

      context 'with invalid submission payload' do
        context 'when missing encrypted_submission' do
          let(:params) { {} }

          before do
            post_request
          end

          it 'validates the submission payload against the schema' do
            expect(response.status).to be(422)
          end

          it 'expect response body to include JSON validator error' do
            expect(response_body).to eq(
              { 'message' => ['Encrypted Submission is missing'] }
            )
          end
        end

        context 'when additional properties in payload' do
          let(:params) do
            {
              encrypted_submission: SubmissionEncryption.new(
                key: submission_decryption_key
              ).encrypt(
                valid_submission_payload.merge(good_movie: 'Rogue one')
              )
            }
          end

          before do
            post_request
          end

          it 'returns unprocessable_entity status code' do
            expect(response.status).to be(422)
          end

          it 'returns the error message in the response body' do
            expect(response_body).to eq(
              'message' => [
                "The property '#/' contains additional properties [\"good_movie\"] outside of the schema when none are allowed"
              ]
            )
          end
        end

        context 'when invalid encrypted submission payload' do
          let(:params) do
            {
              encrypted_submission: SubmissionEncryption.new(
                key: submission_decryption_key
              ).encrypt({})
            }
          end

          before do
            post_request
          end

          it 'returns unprocessable_entity status code' do
            expect(response.status).to be(422)
          end

          it 'returns the error message in the response body' do
            expect(response_body).to eq(
              'message' => ["The property '#/' did not contain a required property of 'service'"]
            )
          end
        end

        context 'when badly encrypted payload' do
          let(:params) do
            {
              encrypted_submission: 'faramir cannot read maps'
            }
          end

          before do
            post_request
          end

          it 'returns unprocessable entity status code' do
            expect(response.status).to eq(422)
          end

          it 'returns the error message in the response body' do
            expect(response_body).to eq(
              'message' => ['Unable to decrypt submission payload']
            )
          end
        end
      end
    end

    context 'with invalid token' do
      let(:params) { {} }

      context 'when token not present' do
        before do
          allow(fb_jwt_auth).to receive(:verify!).and_raise(
            Fb::Jwt::Auth::TokenNotPresentError, 'Token is not present'
          )
          post_request
        end

        it 'returns forbidden' do
          expect(response.status).to be(403)
        end

        it 'returns response body' do
          expect(response_body).to eq('message' => ['Token is not present'])
        end
      end

      context 'when application not present ' do
        before do
          allow(fb_jwt_auth).to receive(:verify!).and_raise(
            Fb::Jwt::Auth::IssuerNotPresentError, 'Issuer is not present'
          )
          post_request
        end

        it 'returns forbidden' do
          expect(response.status).to be(403)
        end

        it 'returns response body' do
          expect(response_body).to eq('message' => ['Issuer is not present'])
        end
      end

      context 'when namespace not present' do
        before do
          allow(fb_jwt_auth).to receive(:verify!).and_raise(
            Fb::Jwt::Auth::NamespaceNotPresentError, 'Namespace is not present'
          )
          post_request
        end

        it 'returns forbidden' do
          expect(response.status).to be(403)
        end

        it 'returns response body' do
          expect(response_body).to eq('message' => ['Namespace is not present'])
        end
      end

      context 'when token is not valid' do
        before do
          allow(fb_jwt_auth).to receive(:verify!).and_raise(
            Fb::Jwt::Auth::TokenNotValidError, 'Token is not valid'
          )
          post_request
        end

        it 'returns forbidden' do
          expect(response.status).to be(403)
        end

        it 'returns response body' do
          expect(response_body).to eq('message' => ['Token is not valid'])
        end
      end

      context 'when token is expired' do
        before do
          allow(fb_jwt_auth).to receive(:verify!).and_raise(
            Fb::Jwt::Auth::TokenExpiredError, 'Token has expired'
          )
          post_request
        end

        it 'returns forbidden' do
          expect(response.status).to be(403)
        end

        it 'returns response body' do
          expect(response_body).to eq('message' => ['Token has expired'])
        end
      end
    end
  end
end
