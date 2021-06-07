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

class DownloadAttachments
  attr_reader :attachments, :target_dir, :token, :access_token

  def initialize(attachments:, target_dir: nil, token:, access_token:, jwt_skew_override:)
    @attachments = attachments
    @target_dir = target_dir
    @token = token
    @access_token = access_token
    @jwt_skew_override = jwt_skew_override
  end

  def download
    actual_dir = target_dir || Dir.mktmpdir

    attachments.each do |attachment|
      url = attachment.fetch('url')
      filename = attachment.fetch('filename')
      mimetype = attachment.fetch('mimetype')
      tmp_path = file_path_for_download(url: url, target_dir: actual_dir)
      request(url: url, file_path: tmp_path, headers: headers)
      results << Attachment.new(url: url, path: tmp_path, filename: filename, mimetype: mimetype)
    end

    results
  end

  private

  def request(url:, file_path:, headers:)
    response = Faraday.get(url, {}, headers)

    File.open(file_path, 'wb') do |f|
      f.write(response.body)
    end
  end

  attr_reader :jwt_skew_override

  def headers
    {
      'x-encrypted-user-id-and-token' => token,
      'x-access-token-v2' => access_token,
      'x-jwt-skew-override' => jwt_skew_override
    }.compact
  end

  def file_path_for_download(url:, target_dir: nil)
    actual_dir = target_dir || Dir.mktmpdir
    filename = File.basename(URI.parse(url).path)
    File.join(actual_dir, filename)
  end
end
