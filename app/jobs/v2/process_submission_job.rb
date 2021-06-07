module V2
  class ProcessSubmissionJob < ApplicationJob
    queue_as :default

    def perform(submission_id:)
      submission = Submission.find(submission_id)
      decrypted_submission = submission.decrypted_submission.merge(
        'submission_id' => submission.id
      )

      pdf_api_gateway = Adapters::PdfApi.new(
        root_url: ENV.fetch('PDF_GENERATOR_ROOT_URL'),
        token: submission.access_token
      )
      pdf_attachment = GeneratePdfContent.new(
        pdf_api_gateway: pdf_api_gateway,
        payload: PdfPayloadTranslator.new(decrypted_submission).to_h
      ).execute

      decrypted_submission['actions'].each do |action|
        next unless action['kind'] == 'email'

        attachments = download_attachments(
          decrypted_submission['attachments'],
          submission.encrypted_user_id_and_token,
          submission.access_token
        )

        EmailOutputService.new(
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

    def download_attachments(attachments, encrypted_user_id_and_token, access_token)
      DownloadAttachments.new(
        attachments: attachments,
        token: encrypted_user_id_and_token,
        access_token: access_token,
        jwt_skew_override: nil,
        target_dir: nil
      ).download
    end
  end
end
