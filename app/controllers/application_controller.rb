class ApplicationController < ActionController::API
  include Concerns::ErrorHandling
  include Concerns::JWTAuthentication

  before_action :consider_all_requests_json
  before_action :enforce_json_only

  private

  def consider_all_requests_json
    request.env['CONTENT_TYPE'] = 'application/json' if request.env['CONTENT_TYPE'] == 'application/x-www-form-urlencoded'
  end

  def enforce_json_only
    response.status = :unacceptable unless request.format.json?
  end
end
