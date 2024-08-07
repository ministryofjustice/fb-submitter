module V2
  class ReplayBatchSubmission
    attr_accessor :date_from, :date_to, :service_slug, :new_destination_email, :resend_json, :resend_mslist

    ALLOWED_DOMAINS = [
      'justice.gov.uk',
      'digital.justice.gov.uk',
      'cica.gov.uk',
      'ccrc.gov.uk',
      'judicialappointments.gov.uk',
      'judicialombudsman.gov.uk',
      'ospt.gov.uk',
      'gov.sscl.com',
      'hmcts.net'
    ].freeze

    TWENTY_EIGHT_DAYS_IN_SECONDS = 28 * 24 * 60 * 60

    def initialize(date_from:, date_to:, service_slug:, new_destination_email:, resend_json: false, resend_mslist: false)
      @date_from = DateTime.parse(date_from)
      @date_to = DateTime.parse(date_to)
      @service_slug = service_slug
      @new_destination_email = new_destination_email
      @resend_json = resend_json
      @resend_mslist = resend_mslist
    end

    def call
      raise StandardError, 'Date from must be before Date to' unless validate_dates
      raise StandardError, 'New destination email must be on the allow list' unless validate_destination

      process_submissions
    end

    def validate_dates
      date_from < date_to
    end

    def validate_destination
      new_destination_email.split('@').last.downcase.in?(ALLOWED_DOMAINS)
    end

    def process_submissions
      submissions = get_submissions_to_process

      submissions.each do |submission|
        Rails.logger.info("Processing submission: #{submission.id} from #{submission.created_at}")
        new_actions = []
        payload = submission.decrypted_submission

        email_action = payload['actions'].find { |a| a['kind'] == 'email' && a['variant'] == 'submission' }
        if email_action.present?
          email_action['to'] = new_destination_email
          new_actions << email_action
        end

        csv_action = payload['actions'].find { |a| a['kind'] == 'csv' }
        if csv_action.present?
          csv_action['to'] = new_destination_email
          new_actions << csv_action
        end

        new_actions << payload['actions'].find { |a| a['kind'] == 'json' } if resend_json
        new_actions << payload['actions'].find { |a| a['kind'] == 'mslist' } if resend_mslist

        payload['actions'] = new_actions

        submission.update!(payload: SubmissionEncryption.new.encrypt(payload))
        submission.save!

        Rails.logger.info("Creating new send job for: #{submission.id} to new destination: #{new_destination_email}")

        V2::ProcessSubmissionJob.perform_later(
          submission_id: submission.id,
          request_id: SecureRandom.uuid,
          jwt_skew_override: TWENTY_EIGHT_DAYS_IN_SECONDS.to_s
        )
      end
    end

    def get_submissions_to_process
      Submission.where(created_at: date_from..date_to, service_slug:)
    end
  end
end
