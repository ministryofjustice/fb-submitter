class ProcessSubmissionService
  attr_reader :submission_id

  def initialize(submission_id:, jwt_skew_override: nil)
    @submission_id = submission_id
    @jwt_skew_override = jwt_skew_override
  end

  # rubocop:disable Metrics/MethodLength
  def perform # rubocop:disable Metrics/AbcSize
    payload_service.actions.each do |action|
      case action.fetch(:type)
      when 'json'
        JsonWebhookService.new(
          webhook_attachment_fetcher: WebhookAttachmentService.new(
            attachment_parser: AttachmentParserService.new(attachments: payload_service.attachments),
            user_file_store_gateway: Adapters::UserFileStore.new(key: submission.encrypted_user_id_and_token)
          ),
          webhook_destination_adapter: Adapters::JweWebhookDestination.new(
            url: action.fetch(:url),
            key: action.fetch(:encryption_key)
          )
        ).execute(
          user_answers: payload_service.user_answers_map,
          service_slug: submission.service_slug,
          payload_submission_id: payload_service.submission_id
        )
      when 'email'
        pdf = generate_pdf(payload_service.payload, payload_service.submission_id)

        attachments = download_attachments(payload_service.attachments,
                                           submission.encrypted_user_id_and_token,
                                           submission.access_token)

        send_email(action:, attachments:, pdf_attachment: pdf)
      when 'csv'
        csv_attachment = generate_csv(payload_service)
        send_email(action:, attachments: [csv_attachment])
      else
        Rails.logger.warn "Unknown action type '#{action.fetch(:type)}' for submission id #{submission.id}"
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  attr_reader :jwt_skew_override

  def download_attachments(attachments_payload, encrypted_user_id_and_token, access_token)
    DownloadAttachments.new(
      attachments: attachments_payload,
      target_dir: nil,
      encrypted_user_id_and_token:,
      access_token:,
      jwt_skew_override:
    ).download
  end

  def generate_pdf(pdf_detail, _payload_submission_id)
    GeneratePdfContent.new(
      pdf_api_gateway: pdf_gateway,
      payload: pdf_detail
    ).execute
  end

  def generate_csv(payload_service)
    GenerateCsvContent.new(payload_service:).execute
  end

  def pdf_gateway
    Adapters::PdfApi.new(
      root_url: ENV.fetch('PDF_GENERATOR_ROOT_URL'),
      token: submission.access_token
    )
  end

  def submission
    @submission ||= Submission.find(submission_id)
  end

  def payload_service
    @payload_service ||= SubmissionPayloadService.new(submission.decrypted_payload)
  end

  # rubocop:disable Metrics/MethodLength
  def send_email(action:, attachments:, pdf_attachment: nil)
    EmailOutputService.new(
      emailer: EmailService,
      attachment_generator: AttachmentGenerator.new,
      encryption_service: EncryptionService.new,
      submission_id:,
      payload_submission_id: payload_service.submission_id
    ).execute(
      action:,
      attachments:,
      pdf_attachment:
    )
  end
  # rubocop:enable Metrics/MethodLength
end
