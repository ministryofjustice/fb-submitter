require 'rails_helper'
require 'webmock/rspec'

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

      include_context 'when a JSON-only API', :get, '/submission/abcdef'
      include_context 'a JWT-authenticated method', :get, '/submission/abcdef', {}

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
    before do
      Delayed::Worker.delay_jobs = false

      stub_request(:get, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-aaa59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e1187aaa').to_return(status: 200, body: '', headers: {})
      stub_request(:get, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8').to_return(status: 200, body: '', headers: {})

      stub_request(:get, 'http://my-service.formbuilder-services-test:3000/some/plain.txt').to_return(status: 200, body: '', headers: {})
      stub_request(:get, 'http://my-service.formbuilder-services-test:3000/some/html').to_return(status: 200, body: '', headers: {})

      stub_request(:get, 'http://my-service.formbuilder-services-test:3000/api/submitter/pdf/default/7a9a5124-0ab2-43f1-b345-0685fced5705.pdf').to_return(status: 200, body: '', headers: {})

      allow(Aws::SES::Client).to receive(:new).with(region: 'eu-west-1').and_return(stub_aws)

      # PDF Generator stubs
      stub_request(:get, 'http://fake_service_token_cache_root_url/service/my-service').to_return(status: 200, body: { token: '123' }.to_json)
      stub_request(:post, 'http://pdf-generator.com/v1/pdfs').with(body: '{"question_1":"answer 1","question_2":"answer 2"}').to_return(status: 200, body: pdf_file_content)
    end

    after do
      Delayed::Worker.delay_jobs = true
    end

    let(:stub_aws) do
      Aws::SES::Client.new(region: 'eu-west-1', stub_responses: true)
    end

    let(:pdf_file_content) { 'pdf binary goes here' }

    describe 'to /submission' do
      let(:url) { '/submission' }
      let(:post_request) do
        post url, params: params.to_json, headers: headers
      end

      include_context 'when a JSON-only API', :post, '/submission'
      include_context 'a JWT-authenticated method', :post, '/submission', {}

      context 'with a valid token' do
        before do
          allow_any_instance_of(ApplicationController).to receive(:verify_token!)
        end

        context 'with a valid email JSON body' do
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
                  { # this is a deprecated version of pdf attachments
                    type: 'output',
                    mimetype: 'application/pdf',
                    url: '/api/submitter/pdf/default/7a9a5124-0ab2-43f1-b345-0685fced5705.pdf',
                    filename: 'form'
                  },
                  { # this is the new version of pdf attachments
                    type: 'output',
                    mimetype: 'application/pdf',
                    url: '/api/submitter/pdf/default/7a9a5124-0ab2-43f1-b345-0685fced5705.pdf',
                    filename: 'form',
                    pdf_data: {
                      question_1: 'answer 1',
                      question_2: 'answer 2'
                    }
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
            let(:raw_messages) do
              stub_aws.api_requests.map do |request|
                request[:params][:raw_message][:data]
              end
            end

            it 'downloads email attachments' do
              post_request
              expect(WebMock).to have_requested(:get, %r{fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/}).times(2)
            end

            it 'downloads pdf attachment answers' do
              post_request
              expect(WebMock).to have_requested(:get, 'http://my-service.formbuilder-services-test:3000/api/submitter/pdf/default/7a9a5124-0ab2-43f1-b345-0685fced5705.pdf').times(1)
            end

            it 'downloads email body parts' do
              post_request
              # TODO: this may be requested more than needed
              expect(WebMock).to have_requested(:get, 'http://my-service.formbuilder-services-test:3000/some/plain.txt').times(4)
              expect(WebMock).to have_requested(:get, 'http://my-service.formbuilder-services-test:3000/some/html').times(4)
            end

            it 'sends 4 emails' do
              post_request
              expect(stub_aws.api_requests.size).to eq(4)
            end

            it 'email contains downloaded attachment' do
              post_request

              file_ccontent = Base64.encode64(pdf_file_content)
              expect(raw_messages.join).to include(file_ccontent)
            end

            it 'creates a submission record' do
              expect { post_request }.to change(Submission, :count).by(1)
            end

            describe 'the created Submission record' do
              let(:created_record) { Submission.last }

              it 'processed requests are marked as completed' do
                post_request
                expect(created_record.status).to eq('completed')
              end

              it 'has the given service_slug' do
                post_request
                expect(created_record.service_slug).to eq(service_slug)
              end

              it 'has given encrypted_user_id_and_token' do
                post_request
                expect(created_record.encrypted_user_id_and_token).to eq(encrypted_user_id_and_token)
              end
            end

            # rubocop:disable RSpec/MessageSpies
            it 'creates a Job to be processed asynchronously' do
              expect(Delayed::Job).to receive(:enqueue)
              post_request
            end
            # rubocop:enable RSpec/MessageSpies

            describe 'the response' do
              before do
                post_request
              end

              it 'has status 201' do
                expect(response).to have_http_status(:created)
              end
            end
          end
        end
      end
    end
  end
end
