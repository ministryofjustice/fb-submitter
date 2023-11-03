class MetricsController < ActionController::Base
  def show
    response.set_header('Content-Type', 'text/plain; version=0.0.4')
    @stats = [delayed_jobs_stats, submission_stats].flatten

    render 'metrics/show', formats: [:text]
  end

  private

  def delayed_jobs_stats
    pending_job_count = Delayed::Job.where('attempts = 0').count
    failed_job_count = Delayed::Job.where('attempts > 0').count

    [
      { name: :delayed_jobs_pending,
        type: 'gauge',
        docstring: 'Number of pending jobs',
        value: pending_job_count },
      { name: :delayed_jobs_failed,
        type: 'gauge',
        docstring: 'Number of jobs failed',
        value: failed_job_count }
    ]
  end

  def submission_stats
    Submission.group(:service_slug).count.map do |form, count|
      { name: :submissions,
        type: 'counter',
        docstring: 'Number of submissions',
        filter: { form: },
        value: count }
    end
  end

  def filter_to_string(filter)
    return '' if filter.blank?

    filter.to_a.map { |k, v| "#{k}=\"#{v}\"" }.join(',').prepend('{').concat('}')
  end
  helper_method :filter_to_string
end
