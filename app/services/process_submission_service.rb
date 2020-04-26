class ProcessSubmissionService
  attr_reader :submission_id

  def initialize(submission_id:)
    @submission_id = submission_id
  end

  # rubocop:disable Metrics/MethodLength
  def process # rubocop:disable Metrics/AbcSize
    payload_service.actions.each do |action|
      case action.fetch(:type)
      when 'json'
        JsonWebhookService.new(
          webhook_attachment_fetcher: webhook_attachment_fetcher,
          webhook_destination_adapter: Adapters::JweWebhookDestination
        ).execute(
          user_answers: payload_service.user_answers_map,
          service_slug: submission.service_slug,
          submission_id: payload_service.submission_id,
          url: action.fetch(:url),
          key: action.fetch(:encryption_key)
        )
      when 'email'
        pdf = generate_pdf(payload_service.payload, payload_service.submission_id)

        attachments = download_attachments(payload_service.attachments,
                                           submission.encrypted_user_id_and_token,
                                           submission.access_token)

        EmailOutputService.new(
          emailer: EmailService,
          attachment_generator: AttachmentGenerator.new
        ).execute(submission_id: payload_service.submission_id,
                  action: action,
                  attachments: attachments,
                  pdf_attachment: pdf)
      when 'csv'
        csv_attachment = generate_csv(payload_service)

        EmailOutputService.new(
          emailer: EmailService,
          attachment_generator: AttachmentGenerator.new
        ).execute(submission_id: payload_service.submission_id,
                  action: action,
                  attachments: [csv_attachment],
                  pdf_attachment: nil)
      else
        Rails.logger.warn "Unknown action type '#{action.fetch(:type)}' for submission id #{submission.id}"
      end
    end

    Metrics.new(submission).track(
      'Submission',
      { form: submission.service_slug }
    )
  end
  # rubocop:enable Metrics/MethodLength

  private

  def download_attachments(attachments_payload, token, access_token)
    DownloadService.new(
      attachments: attachments_payload,
      target_dir: nil,
      token: token,
      access_token: access_token
    ).download_in_parallel
  end

  def generate_pdf(pdf_detail, _submission_id)
    GeneratePdfContent.new(
      pdf_api_gateway: pdf_gateway,
      payload: pdf_detail
    ).execute
  end

  def generate_csv(payload_service)
    GenerateCsvContent.new(payload_service: payload_service).execute
  end

  def pdf_gateway
    Adapters::PdfApi.new(
      root_url: ENV.fetch('PDF_GENERATOR_ROOT_URL'),
      token: submission.access_token
    )
  end

  def webhook_attachment_fetcher
    WebhookAttachmentService.new(
      attachment_parser: AttachmentParserService.new(attachments: payload_service.attachments),
      user_file_store_gateway: Adapters::UserFileStore.new(key: submission.encrypted_user_id_and_token)
    )
  end

  def submission
    @submission ||= Submission.find(submission_id)
  end

  def payload_service
    @payload_service ||= SubmissionPayloadService.new(submission.decrypted_payload)
  end
end
