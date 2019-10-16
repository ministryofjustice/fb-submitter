# frozen_string_literal: true

# rubocop:disable all
class ProcessSubmissionService
  attr_reader :submission_id

  def initialize(submission_id:)
    @submission_id = submission_id
  end

  def perform
    submission.update_status(:processing)
    submission.responses = []

    token = submission.encrypted_user_id_and_token
    submission.submission_details.each do |submission_detail|
      submission_detail = submission_detail.with_indifferent_access

      if submission_detail.fetch(:type) == 'json'
        encryption_key = submission_detail.fetch(:encryption_key)

        JsonWebhookService.new(
          runner_callback_adapter: Adapters::RunnerCallback.new(url: submission_detail.fetch(:data_url), token: token),
          webhook_attachment_fetcher: WebhookAttachmentService.new(
            attachment_parser: AttachmentParserService.new(attachments: submission_detail.fetch(:attachments)),
            user_file_store_gateway: Adapters::UserFileStore.new(key: token)
          ),
          webhook_destination_adapter: Adapters::JweWebhookDestination.new(url: submission_detail.fetch(:url), key: encryption_key)
        ).execute(service_slug: submission.service_slug)
      end
    end

    submission.detail_objects.to_a.each do |submission_detail|
      send_email(submission_detail) if submission_detail.instance_of? EmailSubmissionDetail
    end

    # explicit save! first, to save the responses
    submission.save!

    submission.complete!
  end

  private

  def send_email(mail)
    if number_of_attachments(mail) <= 1
      response = EmailService.send_mail(
        from: mail.from,
        to: mail.to,
        subject: mail.subject,
        body_parts: retrieve_mail_body_parts(mail),
        attachments: attachments(mail)
      )

      submission.responses << response.to_h
    else
      attachments(mail).each_with_index do |a, n|
        response = EmailService.send_mail(
          from: mail.from,
          to: mail.to,
          subject: "#{mail.subject} {#{submission_id}} [#{n + 1}/#{number_of_attachments(mail)}]",
          body_parts: retrieve_mail_body_parts(mail),
          attachments: [a]
        )

        submission.responses << response.to_h
      end
    end
  end

  def number_of_attachments(mail)
    attachments(mail).size
  end

  # returns array of urls
  # this is done over all files so we download all needed files at once
  def unique_attachment_urls
    attachments = submission.detail_objects.map(&:attachments).flatten
    urls = attachments.map { |e| e['url'] }
    urls.sort.uniq
  end

  def retrieve_mail_body_parts(mail)
    body_part_map = download_body_parts(mail)
    read_downloaded_body_parts(mail, body_part_map)
  end

  # returns Hash
  # { type: url }
  # { 'text' => http://example.com/foo.text }
  def download_body_parts(mail)
    DownloadService.download_in_parallel(
      urls: mail.body_parts.values,
      headers: headers
    )
  end

  def read_downloaded_body_parts(mail, body_part_map)
    # we need to send the body parts as strings
    body_part_content = {}
    mail.body_parts.each do |type, url|
      body_part_content[type] = File.open(body_part_map[url]) { |f| f.read }
    end
    body_part_content
  end

  def submission
    @submission ||= Submission.find(submission_id)
  end

  def headers
    { 'x-encrypted-user-id-and-token' => submission.encrypted_user_id_and_token }
  end

  def attachments(mail)
    @generated_attachments ||= generate_attachments(mail.attachments.map(&:with_indifferent_access))
  end

  def generate_attachments(attachments)
    attachment_objects = AttachmentParserService.new(attachments: attachments).execute

    attachments.each_with_index do |value, index|
      if value[:pdf_data]
        attachment_objects[index].file = generate_pdf({submission: value[:pdf_data]}, @submission_id)
      else
        attachment_objects[index].path = download_attachments[attachment_objects[index].url]
      end
    end
    attachment_objects
  end

  def download_attachments
    @url_file_map ||= DownloadService.download_in_parallel(
      urls: unique_attachment_urls,
      headers: headers
    )
  end

  def generate_pdf(pdf_detail, submission_id)
    SaveTempPdf.new(
      generate_pdf_content_service: GeneratePdfContent.new(
        pdf_api_gateway: pdf_gateway(submission.service_slug),
        payload: pdf_detail.with_indifferent_access
      ),
      tmp_file_gateway: Tempfile
    ).execute(file_name: submission_id)
  end

  def pdf_gateway(service_slug)
    token = JwtAuthService.new(
      service_token_cache: Adapters::ServiceTokenCacheClient.new(
        root_url: ENV.fetch('SERVICE_TOKEN_CACHE_ROOT_URL')
      ),
      service_slug: service_slug
    ).execute

    Adapters::PdfApi.new(root_url: ENV.fetch('PDF_GENERATOR_ROOT_URL'), token: token)
  end
end
# rubocop:enable all
