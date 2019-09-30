module Adapters
  class ServiceUrlResolver
    attr_accessor :service_slug, :environment_slug

    def initialize(params = {})
      @service_slug = params[:service_slug]
      @environment_slug = params[:environment_slug] || ENV['FB_ENVIRONMENT_SLUG']
    end

    def ensure_absolute_urls(urls = [])
      urls.map { |u| ensure_absolute_url(u) }
    end

    def ensure_absolute_url(url)
      uri = URI.parse(url)
      uri = resolve_uri_to_service(uri) unless uri.absolute?
      uri.to_s
    end

    def resolve_uri_to_service(uri)
      uri.host = internal_host(service_slug, environment_slug)
      uri.scheme = ENV['INTERNAL_SERVICE_PROTOCOL'] || 'http'
      uri.port = ENV['INTERNAL_SERVICE_PORT'] || 3000
      uri
    end

    private

    def internal_host(service_slug, environment_slug)
      "#{service_slug}.formbuilder-services-#{environment_slug}"
    end
  end
end
