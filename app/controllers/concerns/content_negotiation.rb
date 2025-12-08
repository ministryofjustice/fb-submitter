require 'active_support/concern'

module ContentNegotiation
  extend ActiveSupport::Concern

  included do
    before_action :consider_all_requests_json
    before_action :enforce_json_only
  end

  def consider_all_requests_json
    request.env['CONTENT_TYPE'] = 'application/json' if request.env['CONTENT_TYPE'] == 'application/x-www-form-urlencoded'
  end

  def enforce_json_only
    unless request.format.json?
      render json: { error: 'Format not acceptable' }, status: :not_acceptable
    end
  end
end
