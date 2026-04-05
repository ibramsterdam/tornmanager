class Factions::Leadership::ActivityController < Factions::Leadership::BaseController
  MIN_POLLS_FOR_DATA = 96 # 24 hours * 4 polls per hour

  def show
    poll_count = @faction.member_activity_snapshots.distinct.count(:recorded_at)

    unless poll_count >= MIN_POLLS_FOR_DATA
      redirect_to faction_leadership_path(@faction), notice: "Activity data is still being collected. Check back in a few hours."
      return
    end

    @dates = ((Date.current - 13)..Date.current).to_a
    @member_count = @faction.users.active.count
    @calendar = MemberActivitySnapshot.calendar_heatmap(@faction.id, @dates.first, @dates.last)
    @max_heatmap_value = @calendar.values.max || 1
    @members = MemberActivitySnapshot.member_summary(@faction.id)
    @earliest_snapshot = @faction.member_activity_snapshots.minimum(:recorded_at)
    @first_data_date = @earliest_snapshot&.to_date || Date.current
    @member_hourly = MemberActivitySnapshot.member_hourly_summary(@faction.id)
    build_chain_coverage
  end

  private

  def build_chain_coverage
    polls_per_hour = 4
    @hourly_avg = (0..23).map do |hour|
      counts = @dates.map { |date| (@calendar[[ date.to_s, hour ]] || 0) / polls_per_hour }
      avg = counts.sum.to_f / counts.size
      { hour: hour, avg: avg.round, min: counts.min, max: counts.max }
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
          finalize_window(current_window)
          @danger_windows << current_window
          current_window = nil
        end
      end
    end

    if current_window
      finalize_window(current_window)
      @danger_windows << current_window
    end
  end

  def finalize_window(window)
    window[:avg] = (window[:hours].sum { |x| x[:avg] } / window[:hours].size).round
    window[:min] = window[:hours].map { |x| x[:min] }.min
    window[:duration] = window[:hours].size
  end
end
