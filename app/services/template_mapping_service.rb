class TemplateMappingService
  class MissingTemplate < StandardError; end

  class Email
    ALL = {
      'email.return.setup.email.token' => ENV['NOTIFY_EMAIL_RETURN_SETUP_EMAIL_TOKEN'],
      'email.return.setup.email.verified' => ENV['NOTIFY_EMAIL_RETURN_SETUP_EMAIL_VERIFIED'],
      'email.return.setup.mobile.verified' => ENV['NOTIFY_EMAIL_RETURN_SETUP_MOBILE_VERIFIED'],
      'email.return.signin.email' => ENV['NOTIFY_EMAIL_RETURN_SIGNIN_EMAIL'],
      'email.return.signin.success' => ENV['NOTIFY_EMAIL_RETURN_SIGNIN_SUCCESS'],
      'email.generic' => ENV['NOTIFY_EMAIL_GENERIC']
    }.freeze

    def self.template_id_for_name(name)
      ALL.fetch(name) do
        raise MissingTemplate
      end
    end
  end

  class Sms
    ALL = {
      'sms.return.setup.mobile' => ENV['NOTIFY_SMS_RETURN_SETUP_MOBILE'],
      'sms.return.signin.mobile' => ENV['NOTIFY_SMS_RETURN_SIGNIN_MOBILE'],
      'sms.generic' => ENV['NOTIFY_SMS_GENERIC']
    }.freeze

    def self.template_id_for_name(name)
      ALL.fetch(name) do
        raise MissingTemplate
      end
    end
  end
end
