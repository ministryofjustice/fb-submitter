# frozen_string_literal: true

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

  # returns an array of Attachment objects
  def attachments(mail)
    array = mail.attachments.map do |object|
      object['path'] = url_file_map[object['url']]
      object
    end
    array.map { |o| Attachment.new(o.symbolize_keys) }
  end

  def url_file_map
    @url_file_map ||= DownloadService.download_in_parallel(
      urls: unique_attachment_urls,
      headers: headers
    )
  end
end
