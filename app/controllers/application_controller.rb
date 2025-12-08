require_relative 'concerns/content_negotiation'
require_relative 'concerns/error_handling'
require_relative 'concerns/jwt_authentication'
require_relative 'concerns/v2_error_handling'

class ApplicationController < ActionController::API
  include ErrorHandling
  include JWTAuthentication
  include ContentNegotiation
end
