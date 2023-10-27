class HealthController < ActionController::API
  # used by liveness probe
  def show
    render plain: 'healthy'
  end

  def readiness
    if ActiveRecord::Base.connection && ActiveRecord::Base.connected?
      render plain: 'ready'
    else
      render plain: 'not_ready', status: :service_unavailable
    end
  end
end
