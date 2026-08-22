module Daily
  class FactionMemberSyncJob < ApplicationJob
    include GapBackfill

    queue_as :default

    def perform
      Faction.where(setup_completed: true).includes(:torn_api_key).find_each do |faction|
        next unless faction.torn_api_key&.key

        sync_and_enqueue(faction)
      rescue TornApi::ApiError, TornApi::InvalidKeyError => e
        Rails.logger.error("[FactionMemberSync] Failed for #{faction.name}: #{e.message}")
      end
    end

    private

    def sync_and_enqueue(faction)
      api_key = faction.torn_api_key.key
      members = TornApi::Faction::Members.new(api_key, faction.torn_id).fetch

      sync_members(faction, members, api_key)

      members.each do |member|
        next if member.status_state == "Fallen"

        user = User.find_by(torn_id: member.id)
        next unless user

        FetchPersonalStatsJob.perform_later(user, api_key: api_key)
        backfill_gaps(user, api_key)
      end
    end

    def sync_members(faction, members, api_key)
      member_torn_ids = members.map(&:id)

      User.where(faction_id: faction.id)
          .where.not(torn_id: member_torn_ids)
          .update_all(faction_id: nil)

      members.each do |member|
        user = User.find_or_initialize_by(torn_id: member.id)
        newly_tracked = user.faction_id != faction.id
        user.assign_attributes(
          name: member.name,
          level: member.level,
          faction_id: faction.id,
          position: member.position,
          fallen: member.status_state == "Fallen"
        )
        user.save!

        schedule_backfill(user, api_key) if newly_tracked
      end
    end

    def schedule_backfill(user, api_key)
      start_date = PersonalStatSnapshot.tracking_start_date
      end_date = PersonalStatSnapshot.tracking_end_date
      days = (end_date - start_date).to_i + 1

      estimated_seconds = (days * 2 * BackfillPersonalStatsJob::SECONDS_PER_API_CALL).ceil
      user.update!(backfill_ends_at: Time.current + estimated_seconds.seconds)

      BackfillUserStatsJob.perform_later(user.id, start_date.to_s, end_date.to_s, api_key: api_key)
    end
  end
end
