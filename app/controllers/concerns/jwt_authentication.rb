require 'active_support/concern'

module JWTAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :verify_token!

    if ancestors.include?(ErrorHandling)
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
    unless access_token
      raise Exceptions::TokenNotPresentError
    end

    verify
  end

  def verify
    hmac_secret = public_key(params[:service_slug])
    payload, _header = JWT.decode(
      access_token,
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
      Rails.logger.warn("iat skew is #{iat_skew}, max is #{leeway} - INVALID")
      raise Exceptions::TokenNotValidError
    end

    Rails.logger.debug 'token is valid'
  rescue StandardError => e
    Rails.logger.warn("Couldn't parse that token - error #{e}")
    raise Exceptions::TokenNotValidError
  end

  def leeway
    ENV['MAX_IAT_SKEW_SECONDS'].to_i
  end

  def access_token
    request.headers['x-access-token-v2']
  end

  def request_id
    request.headers['x-request-id']
  end

  def public_key(service_slug)
    service = ServiceTokenService.new(service_slug:, request_id:)
    public_key = service.public_key

    OpenSSL::PKey::RSA.new(public_key)
  end
end
