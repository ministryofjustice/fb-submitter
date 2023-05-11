module V2
  class ProcessSubmissionJob < ApplicationJob
    queue_as :default

    def perform(submission_id:, jwt_skew_override: nil)
      submission = Submission.find(submission_id)
      decrypted_submission = submission.decrypted_submission.merge('submission_id' => submission.id)
      payload_service = V2::SubmissionPayloadService.new(decrypted_submission)

      decrypted_submission['actions'].each do |action|
        case action['kind']
        when 'json'
          JsonWebhookService.new(
            webhook_attachment_fetcher: WebhookAttachmentService.new(
              attachment_parser: AttachmentParserService.new(attachments: payload_service.attachments),
              user_file_store_gateway: Adapters::UserFileStore.new(key: submission.encrypted_user_id_and_token)
            ),
            webhook_destination_adapter: Adapters::JweWebhookDestination.new(
              url: action['url'],
              key: action['encryption_key']
            )
          ).execute(
            user_answers: payload_service.user_answers,
            service_slug: submission.service_slug,
            payload_submission_id: payload_service.submission_id
          )
        when 'email'
          pdf_api_gateway = Adapters::PdfApi.new(
            root_url: ENV.fetch('PDF_GENERATOR_ROOT_URL'),
            token: submission.access_token
          )
          pdf_attachment = GeneratePdfContent.new(
            pdf_api_gateway:,
            payload: PdfPayloadTranslator.new(decrypted_submission).to_h
          ).execute

          attachments = download_attachments(
            decrypted_submission['attachments'],
            submission.encrypted_user_id_and_token,
            submission.access_token,
            jwt_skew_override
          )

          send_email(submission:, action:, attachments:, pdf_attachment:)
        when 'csv'
          csv_attachment = V2::GenerateCsvContent.new(payload_service:).execute

          send_email(submission:, action:, attachments: [csv_attachment])
        else
          Rails.logger.warn "Unknown action type '#{action}' for submission id #{submission.id}"
        end
      end
    end

    def download_attachments(attachments, encrypted_user_id_and_token, access_token, jwt_skew_override)
      DownloadAttachments.new(
        attachments:,
        encrypted_user_id_and_token:,
        access_token:,
        jwt_skew_override:,
        target_dir: nil
      ).download
    end

    def send_email(submission:, action:, attachments:, pdf_attachment: nil)
      EmailOutputServiceV2.new(
        emailer: EmailService,
        attachment_generator: AttachmentGenerator.new,
        encryption_service: EncryptionService.new,
        submission_id: submission.id,
        payload_submission_id: submission.id
      ).execute(
        action: action.symbolize_keys,
        attachments:,
        pdf_attachment:
      )
    end
  end
end
