class ProcessSubmissionService
  attr_reader :submission_id

  def initialize(submission_id:)
    @submission_id = submission_id
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
        ).execute(user_answers: payload_service.user_answers_map, service_slug: submission.service_slug, submission_id: payload_service.submission_id)
      when 'email'
        pdf = generate_pdf(payload_service.payload, payload_service.submission_id)
        attachments = generate_attachments(payload_service.attachments, submission.encrypted_user_id_and_token)

        EmailOutputService.new(
          emailer: EmailService
        ).execute(submission_id: payload_service.submission_id, action: action, attachments: attachments, pdf_attachment: pdf)
      else
        Rails.logger.warn "Unknown action type '#{action.fetch(:type)}' for submission id #{submission.id}"
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  def generate_attachments(attachments_payload, token)
    DownloadService.new(
      attachments: attachments_payload,
      target_dir: nil,
      token: token
    ).download_in_parallel
  end

  def generate_pdf(pdf_detail, _submission_id)
    GeneratePdfContent.new(
      pdf_api_gateway: pdf_gateway(submission.service_slug),
      payload: pdf_detail
    ).execute
  end

  def pdf_gateway(service_slug)
    Adapters::PdfApi.new(
      root_url: ENV.fetch('PDF_GENERATOR_ROOT_URL'),
      token: authentication_token(service_slug)
    )
  end

  def authentication_token(service_slug)
    return if disable_jwt?

    JwtAuthService.new(
      service_token_cache: Adapters::ServiceTokenCacheClient.new(
        root_url: ENV.fetch('SERVICE_TOKEN_CACHE_ROOT_URL')
      ),
      service_slug: service_slug
    ).execute
  end

  def submission
    @submission ||= Submission.find(submission_id)
  end

  def payload_service
    @payload_service ||= SubmissionPayloadService.new(submission.payload)
  end

  def disable_jwt?
    Rails.env.development?
  end
end
