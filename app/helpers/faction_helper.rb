module FactionHelper
  def stat_compliance(actual_daily, target)
    return :green if target.nil? || target.zero?

    ratio = actual_daily.to_f / target.to_f

    if ratio >= 1.0
      :green
    elsif ratio >= 0.6  # 60% of target
      :yellow
    else
      :red
    end
  end

  def member_compliance_level(xanax_status, energy_status, nerve_status)
    statuses = [ xanax_status, energy_status, nerve_status ]

    if statuses.all? { |s| s == :green }
      :compliant
    elsif statuses.any? { |s| s == :red }
      :danger
    else
      :warning
    end
  end

  def compliance_score(xanax_daily, energy_daily, nerve_daily, faction)
    energy_disabled = faction.energy_refill_target.zero?
    nerve_disabled = faction.nerve_refill_target.zero?

    bonus = (energy_disabled ? 30 : 0) + (nerve_disabled ? 30 : 0)
    xanax_weight = 40 + bonus
    energy_weight = energy_disabled ? 0 : 30
    nerve_weight = nerve_disabled ? 0 : 30

    xanax_score = [ (xanax_daily.to_f / faction.xanax_target.to_f) * xanax_weight, xanax_weight ].min
    energy_score = energy_disabled ? 0 : [ (energy_daily.to_f / faction.energy_refill_target.to_f) * energy_weight, energy_weight ].min
    nerve_score = nerve_disabled ? 0 : [ (nerve_daily.to_f / faction.nerve_refill_target.to_f) * nerve_weight, nerve_weight ].min

    (xanax_score + energy_score + nerve_score).round
  end

  def compliance_score_ssl(energy_daily, nerve_daily, faction)
    energy_disabled = faction.energy_refill_target.zero?
    nerve_disabled = faction.nerve_refill_target.zero?

    if energy_disabled && nerve_disabled
      100
    elsif energy_disabled
      nerve_score = [ (nerve_daily.to_f / faction.nerve_refill_target.to_f) * 100, 100 ].min
      nerve_score.round
    elsif nerve_disabled
      energy_score = [ (energy_daily.to_f / faction.energy_refill_target.to_f) * 100, 100 ].min
      energy_score.round
    else
      energy_score = [ (energy_daily.to_f / faction.energy_refill_target.to_f) * 50, 50 ].min
      nerve_score = [ (nerve_daily.to_f / faction.nerve_refill_target.to_f) * 50, 50 ].min
      (energy_score + nerve_score).round
    end
  end

  def compliance_icon(level)
    case level
    when :compliant
      "✓"
    when :warning
      "⚠"
    when :danger
      "✗"
    else
      "?"
    end
  end

  def compliance_class(actual_daily, target)
    status = stat_compliance(actual_daily, target)
    "compliance-#{status}"
  end

  def row_compliance_class(level)
    "row-#{level}"
  end

  def member_stats_clipboard_text(row, days, faction, start_date: nil, end_date: nil)
    lines = []

    if start_date.present? && end_date.present?
      formatted_start = start_date.is_a?(String) ? Date.parse(start_date).strftime("%d %b %Y") : start_date.strftime("%d %b %Y")
      formatted_end = end_date.is_a?(String) ? Date.parse(end_date).strftime("%d %b %Y") : end_date.strftime("%d %b %Y")
      lines << "From #{formatted_start} to #{formatted_end} (#{days} days) #{row[:name]} has:"
    else
      lines << "Over the past #{days} days #{row[:name]} has:"
    end

    lines << "- Used #{number_with_delimiter(row[:xanax_gained])} xanax (#{row[:xanax_daily]}/day, target: #{faction.xanax_target}/day)"
    if faction.energy_refill_target > 0
      lines << "- Used #{number_with_delimiter(row[:energy_refills_gained])} energy refills (#{row[:energy_refills_daily]}/day, target: #{faction.energy_refill_target}/day)"
    else
      lines << "- Used #{number_with_delimiter(row[:energy_refills_gained])} energy refills (#{row[:energy_refills_daily]}/day)"
    end
    if faction.nerve_refill_target > 0
      lines << "- Used #{number_with_delimiter(row[:nerve_refills_gained])} nerve refills (#{row[:nerve_refills_daily]}/day, target: #{faction.nerve_refill_target}/day)"
    else
      lines << "- Used #{number_with_delimiter(row[:nerve_refills_gained])} nerve refills (#{row[:nerve_refills_daily]}/day)"
    end
    lines << "- Completed #{number_with_delimiter(row[:missions_gained])} contracts (#{row[:missions_daily]}/day)"
    lines << "- Committed #{number_with_delimiter(row[:crimes_gained])} crimes (#{row[:crimes_daily]}/day)"
    lines << "- Been active for #{number_with_delimiter(row[:activity_time_daily])} min/day"
    lines.join("\n")
  end
end
