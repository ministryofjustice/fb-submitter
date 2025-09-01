module Adapters
  class AmazonSESAdapter
    DEFAULT_FROM_ADDRESS = 'no-reply-moj-forms@justice.gov.uk'.freeze

    # creds automatically retrieved from
    # ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY']
    # opts[:from] will be in the format "Service Name <service.name@example.com>"
    def self.send_mail(opts = {})
      service_name = opts[:from].split('<')[0]

      client.send_email(
        from_email_address: "#{service_name}<#{DEFAULT_FROM_ADDRESS}>",
        destination: {
          to_addresses: [opts[:to]]
        },
        reply_to_addresses: ([opts[:from]] - ["#{service_name}<#{DEFAULT_FROM_ADDRESS}>"]).compact,
        content: {
          raw: {
            data: opts[:raw_message].to_s
          }
        }
      )
    end

    def self.client
      Aws::SESV2::Client.new(region: 'eu-west-1')
    end
  end
end
