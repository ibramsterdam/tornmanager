module Daily
  class DataRetentionCleanupJob < ApplicationJob
    queue_as :default

    SESSION_RETENTION_DAYS = 90
    API_CALL_RETENTION_DAYS = 30
    ARMORY_NEWS_RETENTION_DAYS = 365

    def perform
      cleanup_old_sessions
      cleanup_old_api_calls
      cleanup_old_armory_news
      cleanup_abandoned_chat_rooms
      cleanup_public_chat_messages
      cleanup_stale_factions
    end

    private

    def cleanup_old_sessions
      cutoff = SESSION_RETENTION_DAYS.days.ago
      deleted_count = Session.where("created_at < ?", cutoff).delete_all

      Rails.logger.info "DataRetentionCleanupJob: Deleted #{deleted_count} sessions older than #{SESSION_RETENTION_DAYS} days"
    end

    def cleanup_old_api_calls
      cutoff = API_CALL_RETENTION_DAYS.days.ago
      deleted_count = ApiCall.where("created_at < ?", cutoff).delete_all

      Rails.logger.info "DataRetentionCleanupJob: Deleted #{deleted_count} API calls older than #{API_CALL_RETENTION_DAYS} days"
    end

    def cleanup_old_armory_news
      cutoff = ARMORY_NEWS_RETENTION_DAYS.days.ago
      deleted_count = ArmoryNewsEntry.where("occurred_at < ?", cutoff).delete_all

      Rails.logger.info "DataRetentionCleanupJob: Deleted #{deleted_count} armory news entries older than #{ARMORY_NEWS_RETENTION_DAYS} days"
    end

    def cleanup_abandoned_chat_rooms
      deleted_count = ChatRoom.abandoned.destroy_all.size

      Rails.logger.info "DataRetentionCleanupJob: Deleted #{deleted_count} chat rooms empty for #{ChatRoom::EMPTY_RETENTION_DAYS}+ days"
    end

    def cleanup_public_chat_messages
      cutoff = ChatRoom::PUBLIC_MESSAGE_RETENTION.ago
      scope = ChatMessage.where(chat_room: ChatRoom.public_rooms).where("chat_messages.created_at < ?", cutoff)

      purged_count = scope.joins(:image_attachment).destroy_all.size
      deleted_count = scope.delete_all

      Rails.logger.info "DataRetentionCleanupJob: Deleted #{deleted_count + purged_count} public chat messages (#{purged_count} with images) older than #{ChatRoom::PUBLIC_MESSAGE_RETENTION.inspect}"
    end

    # destroy (not delete_all) so dependent data goes with the faction and
    # members are detached via the users association's nullify.
    def cleanup_stale_factions
      removed = []
      Faction.stale.find_each do |faction|
        faction.destroy!
        removed << "#{faction.name} [#{faction.torn_id}]"
      rescue => e
        Rails.logger.error "DataRetentionCleanupJob: Failed to remove stale faction #{faction.name}: #{e.message}"
      end

      Rails.logger.info "DataRetentionCleanupJob: Removed #{removed.size} stale factions (#{Faction::STALE_AFTER.inspect} without setup or key): #{removed.join(', ')}" if removed.any?
    end
  end
end
