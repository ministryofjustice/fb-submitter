class ServiceTokenService
  attr_reader :service_slug, :request_id

  def initialize(service_slug:, **options)
    @service_slug = service_slug
    @request_id = options[:request_id]
  end

  # TODO: this method seems to not be in use anymore
  # Legacy FB forms are using v2 token cache too
  # Confirm to be sure and cleanup code/tests
  def get
    client.get(service_slug)
  end

  def public_key
    client.public_key_for(service_slug)
  end

  private

  def client
    @client ||= Adapters::ServiceTokenCacheClient.new(request_id:)
  end
end
