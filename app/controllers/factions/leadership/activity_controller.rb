class Factions::Leadership::ActivityController < Factions::Leadership::BaseController
  MIN_POLLS_FOR_DATA = 96 # 24 hours * 4 polls per hour
  DummyMember = Data.define(:torn_member_id, :member_name, :total_snapshots, :online_count, :active_count)

  def show
    @poll_count = @faction.member_activity_snapshots.distinct.count(:recorded_at)
    @has_enough_data = @poll_count >= MIN_POLLS_FOR_DATA

    @dates = ((Date.current - 13)..Date.current).to_a

    if @has_enough_data
      load_real_data
    else
      load_preview_data
    end
  end

  private

  def load_real_data
    @member_count = @faction.users.active.count
    @calendar = MemberActivitySnapshot.calendar_heatmap(@faction.id, @dates.first, @dates.last)
    @max_heatmap_value = @calendar.values.max || 1
    @members = MemberActivitySnapshot.member_summary(@faction.id)
    @peak_hour = MemberActivitySnapshot.peak_hour(@faction.id)
    @earliest_snapshot = @faction.member_activity_snapshots.minimum(:recorded_at)
    @first_data_date = @earliest_snapshot&.to_date || Date.current
    build_chain_coverage
  end

  def load_preview_data
    first_snapshot = @faction.member_activity_snapshots.minimum(:recorded_at)
    data_ready_at = first_snapshot ? first_snapshot + 24.hours : Time.current + 24.hours
    @seconds_remaining = [ (data_ready_at - Time.current).to_i, 0 ].max

    @members = build_dummy_members
    @member_count = @members.size
    @first_data_date = Date.current - 6
    @calendar = build_dummy_calendar
    @max_heatmap_value = @calendar.values.max || 1
    @peak_hour = 20
    build_chain_coverage
  end

  def build_chain_coverage
    @hourly_avg = (0..23).map do |hour|
      counts = @dates.map { |date| @calendar[[ date.to_s, hour ]] || 0 }
      avg = counts.sum.to_f / counts.size
      { hour: hour, avg: avg.round(1), min: counts.min, max: counts.max }
    end
    threshold = @member_count * 0.25
    @danger_windows = []
    current_window = nil

    @hourly_avg.each do |h|
      if h[:avg] < threshold
        if current_window
          current_window[:end_hour] = (h[:hour] + 1) % 24
          current_window[:hours] << h
        else
          current_window = {
            start_hour: h[:hour],
            end_hour: (h[:hour] + 1) % 24,
            hours: [ h ]
          }
        end
      else
        if current_window
          current_window[:avg] = (current_window[:hours].sum { |x| x[:avg] } / current_window[:hours].size).round(1)
          current_window[:min] = current_window[:hours].map { |x| x[:min] }.min
          current_window[:duration] = current_window[:hours].size
          @danger_windows << current_window
          current_window = nil
        end
      end
    end

    if current_window
      current_window[:avg] = (current_window[:hours].sum { |x| x[:avg] } / current_window[:hours].size).round(1)
      current_window[:min] = current_window[:hours].map { |x| x[:min] }.min
      current_window[:duration] = current_window[:hours].size
      @danger_windows << current_window
    end
  end

  def build_dummy_calendar
    hourly_pct = [
      0.25, 0.15, 0.10, 0.05, 0.03, 0.03, 0.05, 0.10,
      0.15, 0.25, 0.35, 0.45, 0.50, 0.55, 0.60, 0.65,
      0.70, 0.80, 0.90, 0.95, 0.90, 0.80, 0.65, 0.40
    ]

    day_multiplier = { 0 => 1.1, 1 => 0.95, 2 => 0.95, 3 => 1.0, 4 => 1.0, 5 => 1.05, 6 => 1.15 }

    data = {}
    @dates.each do |date|
      next if date < @first_data_date
      wday = date.wday
      (0..23).each do |hour|
        variation = ((wday * 7 + hour * 13) % 5) - 2
        value = (@member_count * hourly_pct[hour] * day_multiplier[wday] + variation * 0.3).round.clamp(0, @member_count)
        data[[ date.to_s, hour ]] = value
      end
    end
    data
  end

  def build_dummy_members
    names = %w[ShadowStrike NightHawk BladeRunner CyberPunk IronFist DarkKnight StormChaser FireWolf IcePhoenix ThunderBolt]
    names.map.with_index do |name, i|
      online_pct = (80 - i * 6 + ((i * 17) % 5) - 2).clamp(15, 85)
      active_pct = (online_pct + 5 + ((i * 11) % 10)).clamp(online_pct, 95)
      total = 672
      DummyMember.new(
        1000000 + i,
        name,
        total,
        (total * online_pct / 100.0).to_i,
        (total * active_pct / 100.0).to_i
      )
    end
  end
end
