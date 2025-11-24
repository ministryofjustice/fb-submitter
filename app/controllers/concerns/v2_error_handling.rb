module V2ErrorHandling
  extend ActiveSupport::Concern

  included do |_base|
    fb_jwt_exceptions = [
      Fb::Jwt::Auth::TokenNotPresentError,
      Fb::Jwt::Auth::TokenNotValidError,
      Fb::Jwt::Auth::IssuerNotPresentError,
      Fb::Jwt::Auth::NamespaceNotPresentError,
      Fb::Jwt::Auth::TokenExpiredError
    ]
    rescue_from(*fb_jwt_exceptions) do |exception|
      render json: {
        message: [exception.message]
      }, status: :forbidden
    end
  end
end
