require 'rails_helper'
require 'webmock/rspec'

describe 'UserData API', type: :request do
  describe 'a POST request' do
    let(:headers) { { 'Content-type' => 'application/json' } }
    let(:service_slug) { 'my-service' }
    let(:stub_aws) { Aws::SESV2::Client.new(region: 'eu-west-1', stub_responses: true) }
    let(:pdf_file_content) { 'pdf binary goes here' }
    let(:url) { '/submission' }
    let(:post_request) { post url, params: params.to_json, headers: }
    let(:submission_decryption_key) { SecureRandom.uuid[0..31] }

    before do
      Delayed::Worker.delay_jobs = false

      stub_request(:get, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-aaa59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e1187aaa').to_return(status: 200, body: '', headers: {})
      stub_request(:get, 'http://fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/28d-dae59621acecd4b1596dd0e96968c6cec3fae7927613a12c357e7a62e11877d8').to_return(status: 200, body: '', headers: {})

      allow(Aws::SESV2::Client).to receive(:new).with(region: 'eu-west-1').and_return(stub_aws)

      # PDF Generator stubs
      stub_request(:post, 'http://pdf-generator.com/v1/pdfs').to_return(status: 200, body: pdf_file_content)
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('SUBMISSION_DECRYPTION_KEY').and_return(submission_decryption_key)
    end

    after do
      Delayed::Worker.delay_jobs = true
    end

    include_context 'when a JSON-only API', :post, '/submission'

    context 'with a valid token' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:verify_token!)
        allow_any_instance_of(ApplicationController).to receive(:enforce_json_only).and_return(true)
      end

      context 'with a valid email JSON body' do
        let(:encrypted_user_id_and_token) { 'kdjh9s8db9s87dbosd7b0sd8b70s9d8bs98d7b9s8db' }
        let(:attachments) do
          [
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
        end
        let(:actions) do
          [
            {
              type: 'email',
              variant: 'submission',
              recipientType: 'team',
              from: 'from@example.com',
              to: 'destination@example.com',
              subject: 'Complain about a court or tribunal submission',
              email_body: 'this is the body of the email',
              include_attachments: true,
              include_pdf: true
            }
          ]
        end
        let(:submission_id) { 'a239313d-4d2d-4a16-b5ef-69d6e8e53e86' }
        let(:submission) do
          {
            'submission_id' => submission_id,
            'pdf_heading' => 'Application against a refusal of criminal legal aid on interests of justice grounds',
            'pdf_subheading' => 'IOJ',
            'sections' => [
              {
                'heading' => 'Defendant’s details',
                'summary_heading' => '',
                'questions' => []
              },
              {
                'heading' => '',
                'summary_heading' => '',
                'questions' => [
                  {
                    'label' => 'Full name',
                    'answer' => 'john doe',
                    'key' => 'fullname'
                  },
                  {
                    'label' => 'Date of birth',
                    'answer' => '1 January 1990',
                    'key' => 'dob'
                  }
                ]
              }
            ]
          }
        end
        let(:payload) do
          {
            meta: {
              submission_id:,
              submission_at: '2019-12-18T13:19:29.626Z'
            },
            actions:,
            submission:,
            attachments:
          }
        end
        let(:encrypted_submission) do
          SubmissionEncryption.new(
            key: submission_decryption_key
          ).encrypt(payload)
        end
        let(:params) do
          {
            service_slug:,
            encrypted_user_id_and_token:,
            encrypted_submission:
          }
        end

        context 'when the request is successful' do
          let(:raw_messages) do
            stub_aws.api_requests.map do |request|
              request[:params][:content][:raw][:data]
            end
          end

          it 'downloads email attachments' do
            post_request
            expect(WebMock).to have_requested(:get, %r{fb-user-filestore-api-svc-test-dev.formbuilder-platform-test-dev/service/ioj/user/a239313d-4d2d-4a16-b5ef-69d6e8e53e86/}).times(2)
          end

          # the tmp file sizes are small so there will only ever be a single email
          it 'sends the correct number of emails' do
            post_request
            expect(stub_aws.api_requests.size).to eq(1)
          end

          it 'email contains downloaded attachment' do
            post_request

            file_content = Base64.encode64(pdf_file_content)
            expect(raw_messages.join).to include(file_content)
          end

          it 'email contains email body' do
            post_request

            expect(raw_messages).to all(include('this is the body of the email'))
          end

          it 'sends the PDF of answers in the same email' do
            post_request

            expect(raw_messages.first).to include('1/1')
            expect(raw_messages.first).to include('-answers.pdf')
          end

          it 'creates a submission record' do
            expect { post_request }.to change(Submission, :count).by(1)
          end

          describe 'the created Submission record' do
            let(:created_record) { Submission.last }

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

          it 'creates a Job with short delay to prevent filestore race conditions' do
            freeze_time do
              expect(Delayed::Job).to receive(:enqueue).with(anything, run_at: 3.seconds.from_now)
              post_request
            end
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
