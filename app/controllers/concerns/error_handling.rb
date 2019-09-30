module Concerns
  module ErrorHandling
    extend ActiveSupport::Concern

    included do
      rescue_from StandardError do |e|
        Raven.capture_exception(e)

        args = { message: e.message }
        unless Rails.env.production?
          args.merge!(
            detail: e.class.name.underscore.to_sym,
            location: e.backtrace[0]
          )
        end
        render_json_error :internal_server_error, :internal_server_error, args
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        render_json_error :not_found, :record_not_found
      end
    end

    private

    def render_json_error(status, error_code, extra = {})
      status = (Rack::Utils::SYMBOL_TO_STATUS_CODE[status] || 500) if status.is_a? Symbol

      error = {
        title: I18n.t(:title, scope: [:error_messages, error_code]),
        status: status
      }.merge(extra)

      detail = I18n.t(:detail, scope: [:error_messages, error_code], default: '')
      error[:detail] = detail unless detail.empty?

      render json: { errors: [error] }, status: status
    end
  end
end
