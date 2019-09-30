require 'rails_helper'

describe 'UserData API', type: :request do
  let(:headers) do
    {
      'Content-type' => 'application/json'
    }
  end
  let(:service_slug) { 'my-service' }
  # NOTE: this must be a valid UUID, otherwise ActiveRecord silently
  # ignores it in an initializer
  let(:user_identifier) { SecureRandom.uuid }

  describe 'a GET request' do
    describe 'to /submission/:id' do
      let(:submission_id) { 'abcdef' }
      let(:url) { "/submission/#{submission_id}" }
      let(:get_request) do
        get url, headers: headers
      end

      it_behaves_like 'a JSON-only API', :get, '/submission/abcdef'
      it_behaves_like 'a JWT-authenticated method', :get, '/submission/abcdef', {}

      context 'with a valid token' do
        before do
          allow_any_instance_of(ApplicationController).to receive(:verify_token!)
          get_request
        end

        context 'when the id exists' do
          let(:submission) do
            Submission.create!(
              status: 'queued',
              encrypted_user_id_and_token: '123456789',
              service_slug: 'my-service',
              submission_details: %w[some details]
            )
          end
          let(:submission_id) { submission.id }

          describe 'the response' do
            it 'has status 200' do
              expect(response).to have_http_status(:ok)
            end

            it 'has json content_type' do
              expect(response.content_type).to eq('application/json')
            end

            describe 'the response body' do
              it 'is valid JSON' do
                expect { JSON.parse(response.body) }.not_to raise_error
              end

              it 'is the requested submission rendered as json' do
                expect(response.body).to eq(submission.to_json)
              end
            end
          end
        end
      end
    end
  end

  describe 'a POST request' do
    describe 'to /submission' do
      let(:url) { '/submission' }
      let(:post_request) do
        post url, params: params.to_json, headers: headers
      end

      it_behaves_like 'a JSON-only API', :post, '/submission'
      it_behaves_like 'a JWT-authenticated method', :post, '/submission', {}

      context 'with a valid token' do
        before do
          allow_any_instance_of(ApplicationController).to receive(:verify_token!)
        end

        context 'and a valid email JSON body' do
          let(:encrypted_user_id_and_token) { 'kdjh9s8db9s87dbosd7b0sd8b70s9d8bs98d7b9s8db' }
          let(:submission_details) do
            [
              {
                type: 'email',
                from: 'from@example.com',
                to: 'destination@example.com',
                body_parts: {
                  'text/html' => '/some/html',
                  'text/plain' => '/some/plain.txt'
                },
                attachments: [
                  {
                    type: 'output',
                    mimetype: 'application/pdf',
                    url: '/api/submitter/pdf/default/7a9a5124-0ab2-43f1-b345-0685fced5705.pdf',
                    filename: 'form'
                  },
                  {
                    type: 'filestore',
                    mimetype: 'image/png',
                    url: 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8',
                    filename: 'doge'
                  },
                  {
                    type: 'filestore',
                    mimetype: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                    url: 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-aaa59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e1187aaa',
                    filename: 'word'
                  }
                ]
              }
            ]
          end
          let(:params) do
            {
              service_slug: service_slug,
              encrypted_user_id_and_token: encrypted_user_id_and_token,
              submission_details: submission_details
            }
          end

          context 'when the request is successful' do
            it 'creates a submission record' do
              expect { post_request }.to change(Submission, :count).by(1)
            end

            describe 'the created Submission record' do
              let(:created_record) { Submission.last }

              it 'has status "queued"' do
                post_request
                expect(created_record.status).to eq('queued')
              end

              it 'has the given service_slug' do
                post_request
                expect(created_record.service_slug).to eq(service_slug)
              end

              it 'has given encrypted_user_id_and_token' do
                post_request
                expect(created_record.encrypted_user_id_and_token).to eq(encrypted_user_id_and_token)
              end

              it 'has the given submission_details' do
                post_request
                # NOTE: .to_json is the easiest way to stringify an arbitrary hash/array structure
                expect(created_record.submission_details.to_json).to eq(params[:submission_details].to_json)
              end
            end

            it 'creates a Job to be processed asynchronously' do
              post_request
              expect(Delayed::Job.all.count).to eq(1)
              expect(Delayed::Job.first.handler).to include(Submission.first.id)
              expect(Delayed::Job.first.handler).to include('ProcessSubmissionService')
            end

            describe 'the response' do
              before do
                post_request
              end

              it 'has status 201' do
                expect(response).to have_http_status(:created)
              end

              describe 'the body' do
                it 'is a valid JSON packet' do
                  expect { JSON.parse(body) }.not_to raise_error
                end

                it 'is the new Submission record, serialised to JSON' do
                  expect(body).to eq(Submission.last.to_json)
                end
              end
            end
          end
        end
      end
    end
  end
end
