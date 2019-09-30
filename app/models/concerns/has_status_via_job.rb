module Concerns
  module HasStatusViaJob
    extend ActiveSupport::Concern

    included do
      STATUS = {
        completed: 'completed',
        failed_retryable: 'failed_retryable',
        failed_non_retryable: 'failed_non_retryable',
        queued: 'queued',
        processing: 'processing'
      }.freeze
      validates :status, inclusion: { in: STATUS.values }

      def update_status(new_status)
        update_attributes(status: STATUS[new_status])
      end

      def complete!
        update_attributes(status: STATUS[:completed], completed_at: Time.now)
      end

      def fail!(retryable: false)
        logger.info "in fail!, retryable: #{retryable}"
        status = retryable ? STATUS[:failed_retryable] : STATUS[:failed_non_retryable]
        update_attributes(status: status, completed_at: Time.now)
      end
    end
  end
end
