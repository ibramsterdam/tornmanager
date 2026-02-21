module FactionHelper
  # Calculate compliance level for a stat compared to target
  # Returns :green, :yellow, or :red
  # Target of 0 means this stat is disabled — always compliant
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

  # Calculate overall member compliance based on all three key stats
  # Returns :compliant, :warning, or :danger
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

  # Calculate overall compliance score (0-100)
  # Weights adjust dynamically based on which targets are enabled.
  # Disabled targets (0) get full marks and their weight redistributes.
  def compliance_score(xanax_daily, energy_daily, nerve_daily, faction)
    energy_disabled = faction.energy_refill_target.zero?
    nerve_disabled = faction.nerve_refill_target.zero?

    # Redistribute weight from disabled targets to xanax
    bonus = (energy_disabled ? 30 : 0) + (nerve_disabled ? 30 : 0)
    xanax_weight = 40 + bonus
    energy_weight = energy_disabled ? 0 : 30
    nerve_weight = nerve_disabled ? 0 : 30

    xanax_score = [ (xanax_daily.to_f / faction.xanax_target.to_f) * xanax_weight, xanax_weight ].min
    energy_score = energy_disabled ? 0 : [ (energy_daily.to_f / faction.energy_refill_target.to_f) * energy_weight, energy_weight ].min
    nerve_score = nerve_disabled ? 0 : [ (nerve_daily.to_f / faction.nerve_refill_target.to_f) * nerve_weight, nerve_weight ].min

    (xanax_score + energy_score + nerve_score).round
  end

  # Get icon for compliance level
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

  # Get CSS class for compliance level
  def compliance_class(actual_daily, target)
    status = stat_compliance(actual_daily, target)
    "compliance-#{status}"
  end

  # Get CSS class for row based on overall compliance level
  def row_compliance_class(level)
    "row-#{level}"
  end

  # Generate clipboard text for member stats
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
