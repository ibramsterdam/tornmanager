class SyncFactionMembersJob < AdminApiJob
  def perform(faction_id)
    faction = Faction.find(faction_id)
    api_key = AdminCredentials.api_key
    members = TornApi::Faction::Members.new(api_key, faction.torn_id).fetch

    member_torn_ids = members.map(&:id)

    User.where(faction_id: faction.id)
        .where.not(torn_id: member_torn_ids)
        .update_all(faction_id: nil)

    members.each do |member|
      user = User.find_or_initialize_by(torn_id: member.id)
      new_member = user.new_record?
      user.assign_attributes(
        name: member.name,
        level: member.level,
        faction_id: faction.id,
        fallen: member.status_state == "Fallen"
      )
      user.save!

      schedule_backfill(user) if new_member && faction.track_stats?
    end

    Rails.logger.info "SyncFactionMembersJob: Synced #{members.size} members for faction #{faction.name} [#{faction.torn_id}]"
  rescue TornApi::ApiError => e
    Rails.logger.error "SyncFactionMembersJob: Failed to sync faction #{faction.torn_id}: #{e.message}"
  end

  private

  def schedule_backfill(user)
    start_date = PersonalStatSnapshot.tracking_start_date
    end_date = PersonalStatSnapshot.tracking_end_date
    days = (end_date - start_date).to_i + 1

    estimated_seconds = (days * 2 * BackfillPersonalStatsJob::SECONDS_PER_API_CALL).ceil
    user.update!(backfill_ends_at: Time.current + estimated_seconds.seconds)

    BackfillUserStatsJob.perform_later(user.id, start_date.to_s, end_date.to_s)
  end
end
