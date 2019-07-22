class ProcessSubmissionService
  def initialize(submission_id)
    @submission_id = submission_id
  end

  def perform
    submission.update_status(:processing)
    submission.responses = []

    submission.detail_objects.to_a.each do |mail|
      if number_of_attachments(mail) <= 1
        response = EmailService.send_mail(
          from:         mail.from,
          to:           mail.to,
          subject:      mail.subject,
          body_parts:   retrieve_mail_body_parts(mail),
          attachments:  attachments(mail)
        )

        submission.responses << response.to_h
      else
        attachments(mail).each_with_index do |a,n|
          response = EmailService.send_mail(
            from:         mail.from,
            to:           mail.to,
            subject:      "#{mail.subject} {#{@submission_id}} [#{n+1}/#{number_of_attachments(mail)}]",
            body_parts:   retrieve_mail_body_parts(mail),
            attachments:  [a]
          )

          submission.responses << response.to_h
        end
      end
    end

    # explicit save! first, to save the responses
    submission.save!

    submission.complete!
  end

  private

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
      body_part_content[type] = File.open(body_part_map[url]){|f| f.read}
    end
    body_part_content
  end

  def submission
    Submission.find(@submission_id)
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
    array.map{|o| Attachment.new(o.symbolize_keys)}
  end

  def url_file_map
    @url_file_map ||= DownloadService.download_in_parallel(
      urls: unique_attachment_urls,
      headers: headers
    )
  end
end
