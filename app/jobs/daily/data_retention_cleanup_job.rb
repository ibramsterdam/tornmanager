module Daily
  class DataRetentionCleanupJob < ApplicationJob
    queue_as :default

    # Retention periods (matching Privacy Policy)
    SESSION_RETENTION_DAYS = 90
    API_CALL_RETENTION_DAYS = 30

    def perform
      cleanup_old_sessions
      cleanup_old_api_calls
    end

    private

    def cleanup_old_sessions
      cutoff = SESSION_RETENTION_DAYS.days.ago
      deleted_count = Session.where("created_at < ?", cutoff).delete_all

      Rails.logger.info "DataRetentionCleanupJob: Deleted #{deleted_count} sessions older than #{SESSION_RETENTION_DAYS} days"
      ::Appsignal.set_gauge("data_retention.sessions_deleted", deleted_count) if defined?(::Appsignal)
    end

    def cleanup_old_api_calls
      cutoff = API_CALL_RETENTION_DAYS.days.ago
      deleted_count = ApiCall.where("created_at < ?", cutoff).delete_all

      Rails.logger.info "DataRetentionCleanupJob: Deleted #{deleted_count} API calls older than #{API_CALL_RETENTION_DAYS} days"
      ::Appsignal.set_gauge("data_retention.api_calls_deleted", deleted_count) if defined?(::Appsignal)
    end
  end
end
