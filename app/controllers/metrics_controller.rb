class MetricsController < ActionController::Base
  def show
    response.set_header('Content-Type', 'text/plain; version=0.0.4')
    @stats = delayed_jobs_stats

    render 'metrics/show.text'
  end

  private

  def delayed_jobs_stats
    pending_job_count = Delayed::Job.where('attempts = 0').count
    failed_job_count = Delayed::Job.where('attempts > 0').count

    [
      { name: :delayed_jobs_pending,
        docstring: 'Number of pending jobs',
        value: pending_job_count },
      { name: :delayed_jobs_failed,
        docstring: 'Number of jobs failed',
        value: failed_job_count }
    ]
  end
end
