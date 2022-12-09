module V2
  class ProcessSubmissionJob < ApplicationJob
    queue_as :default

    def perform(submission_id:, jwt_skew_override: nil)
      submission = Submission.find(submission_id)
      payload_service = V2::SubmissionPayloadService.new(submission)

      payload_service.actions.each do |action|
        send()

        case action['kind']
        when 'email'
          pdf_api_gateway = Adapters::PdfApi.new(
            root_url: ENV.fetch('PDF_GENERATOR_ROOT_URL'),
            token: payload_service.access_token
          )
          pdf_attachment = GeneratePdfContent.new(
            pdf_api_gateway: pdf_api_gateway,
            payload: PdfPayloadTranslator.new(payload_service.payload).to_h
          ).execute

          attachments = download_attachments(
            payload_service.attachments,
            payload_service.encrypted_user_id_and_token,
            payload_service.access_token,
            jwt_skew_override
          )

          send_email(submission: submission, action: action, attachments: attachments, pdf_attachment: pdf_attachment)
        when 'csv'
          csv_attachment = V2::GenerateCsvContent.new(payload_service: payload_service).execute

          send_email(submission: submission, action: action, attachments: [csv_attachment])
        when 'json'
          JsonWebhookService.new(
            webhook_attachment_fetcher: webhook_attachments(payload_service.attachments, submission),
            webhook_destination_adapter: webhook_adapter(action)
          ).execute(
            user_answers: payload_service.user_answers,
            service_slug: submission.service_slug,
            payload_submission_id: payload_service.submission_id
          )
        else
          Rails.logger.warn "Unknown action type '#{action}' for submission id #{submission.id}"
        end
      end
    end

    def assign_payload_service(submission_id)
      submission = Submission.find(submission_id)
      decrypted_submission = submission.decrypted_submission.merge('submission_id' => submission.id)
      V2::SubmissionPayloadService.new(decrypted_submission)
    end

    def webhook_attachments(attachments, submission)
      WebhookAttachmentService.new(
        attachment_parser: AttachmentParserService.new(attachments: attachments),
        user_file_store_gateway: Adapters::UserFileStore.new(key: submission.encrypted_user_id_and_token)
      )
    end

    def webhook_adapter(action)
      Adapters::JweWebhookDestination.new(url: action['url'], key: action['encryption_key'])
    end

    def download_attachments(attachments, encrypted_user_id_and_token, access_token, jwt_skew_override)
      DownloadAttachments.new(
        attachments: attachments,
        encrypted_user_id_and_token: encrypted_user_id_and_token,
        access_token: access_token,
        jwt_skew_override: jwt_skew_override,
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
        attachments: attachments,
        pdf_attachment: pdf_attachment
      )
    end
  end
end
