class Factions::Leadership::DataCoverageController < Factions::Leadership::BaseController
  def show
    load_data_coverage
    load_member_coverage
  end

  private

  def load_member_coverage
    members = @faction.users.active.order(:name)
    start_date = PersonalStatSnapshot.tracking_start_date
    end_date = PersonalStatSnapshot.tracking_end_date
    @expected_days = (start_date..end_date).count

    snapshot_counts = PersonalStatSnapshot
      .where(user_id: members.pluck(:id))
      .where(date: start_date..end_date)
      .group(:user_id)
      .count

    yesterday_user_ids = PersonalStatSnapshot
      .where(user_id: members.pluck(:id), date: Date.yesterday)
      .pluck(:user_id)
      .to_set

    @member_coverage = members.map do |member|
      existing = snapshot_counts[member.id] || 0
      missing = @expected_days - existing
      rate = @expected_days > 0 ? (existing.to_f / @expected_days * 100).round(1) : 0.0

      {
        user: member,
        existing: existing,
        missing: missing,
        rate: rate,
        has_yesterday: yesterday_user_ids.include?(member.id)
      }
    end.sort_by { |m| m[:rate] }

    @tracking_start = start_date
    @tracking_end = end_date
  end
end
