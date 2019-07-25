class MetricsController < ActionController::Base
  def show
    response.headers['version'] = '0.0.4'
    @stats = delayed_jobs_stats
  end

  private

  def delayed_jobs_stats
    pending_job_count = Delayed::Job.where('attempts = 0').count
    failed_job_count = Delayed::Job.where('attempts > 0').count

    [
      { name: :resque_jobs_pending,
        docstring: 'Number of pending jobs',
        value: pending_job_count
      },
      { name: :resque_jobs_failed,
        docstring: 'Number of jobs failed',
        value: failed_job_count
      }
    ]
  end
end
