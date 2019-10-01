require 'rails_helper'

RSpec.describe MetricsController do
  describe 'GET #show' do
    render_views

    let(:job) { Delayed::Job.create! }

    context 'with a pending job' do
      before do
        job.update(attempts: 0)
        get :show, format: 'text'
      end

      it 'shows pending jobs' do
        expected_result = '# TYPE delayed_jobs_pending gauge
# HELP delayed_jobs_pending Number of pending jobs
delayed_jobs_pending 1'
        expect(response.body).to include(expected_result)
      end
    end

    context 'when a failed job' do
      before do
        job.update(attempts: 1)
        get :show, format: 'text'
      end

      it 'shows failed jobs' do
        expected_result = '# TYPE delayed_jobs_failed gauge
# HELP delayed_jobs_failed Number of jobs failed
delayed_jobs_failed 1'

        expect(response.body).to include(expected_result)
      end
    end

    describe 'Response headers' do
      before { get :show, format: 'html' }

      it 'adds the prometheus version' do
        expect(response.headers['Content-Type']).to eq('text/plain; version=0.0.4')
      end
    end
  end
end
