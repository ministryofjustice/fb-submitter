class JwtAuthService
  def initialize(service_token_cache:, service_slug:)
    @service_token_cache = service_token_cache
    @service_slug = service_slug
  end

  def execute
    secret = service_token_cache.get(service_slug)
    JWT.encode({}, secret, 'HS256', iss: service_slug)
  end

  private

  attr_reader :service_token_cache, :service_slug
end
