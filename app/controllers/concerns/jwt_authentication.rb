module Concerns
  module JWTAuthentication
    extend ActiveSupport::Concern

    included do
      before_action :verify_token!

      if ancestors.include?(Concerns::ErrorHandling)
        rescue_from Exceptions::TokenNotPresentError do |_e|
          render_json_error :unauthorized, :token_not_present
        end
        rescue_from Exceptions::TokenNotValidError do |_e|
          render_json_error :forbidden, :token_not_valid
        end
      end
    end

    private

    def verify_token!
      unless request.headers['x-access-token-v2']
        raise Exceptions::TokenNotPresentError
      end

      verify
    end

    def verify
      token = request.headers['x-access-token-v2']

      begin
        hmac_secret = public_key(params[:service_slug])
        payload, _header = JWT.decode(
          token,
          hmac_secret,
          true,
          {
            exp_leeway: leeway,
            algorithm: 'RS256'
          }
        )

        # NOTE: verify_iat used to be in the JWT gem, but was removed in v2.2
        # so we have to do it manually
        iat_skew = payload['iat'].to_i - Time.zone.now.to_i

        if iat_skew.abs > leeway.to_i
          Rails.logger.debug("iat skew is #{iat_skew}, max is #{leeway} - INVALID")
          raise Exceptions::TokenNotValidError
        end

        Rails.logger.debug 'token is valid'
      rescue StandardError => e
        Rails.logger.debug("Couldn't parse that token - error #{e}")
        raise Exceptions::TokenNotValidError
      end
    end

    def leeway
      ENV['MAX_IAT_SKEW_SECONDS'].to_i
    end

    def public_key(service_slug)
      service = ServiceTokenService.new(service_slug:)
      public_key = service.public_key

      OpenSSL::PKey::RSA.new(public_key)
    end
  end
end
