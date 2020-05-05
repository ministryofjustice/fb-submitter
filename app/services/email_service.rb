class EmailService
  def self.send_mail(opts = {})
    adapter.send_mail(sanitised_params(opts))
  end

  def self.sanitised_params(opts = {})
    override_params = {}
    override_params[:to] = ENV['OVERRIDE_EMAIL_TO'] if ENV['OVERRIDE_EMAIL_TO'].present?
    override_params[:raw_message] = RawMessage.new(opts.merge(override_params))

    opts.merge(override_params)
  end

  def self.adapter
    if ENV['EMAIL_ENDPOINT_OVERRIDE'].present?
      return Adapters::MockAmazonSESAdapter
    end

    Adapters::AmazonSESAdapter
  end
end
