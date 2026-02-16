module FactionHelper
  # Calculate compliance level for a stat compared to target
  # Returns :green, :yellow, or :red
  def stat_compliance(actual_daily, target)
    return :red if target.nil? || target.zero?

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
  # Xanax weighted at 40%, energy and nerve at 30% each
  def compliance_score(xanax_daily, energy_daily, nerve_daily, faction)
    xanax_score = [ (xanax_daily.to_f / faction.xanax_target.to_f) * 40, 40 ].min
    energy_score = [ (energy_daily.to_f / faction.energy_refill_target.to_f) * 30, 30 ].min
    nerve_score = [ (nerve_daily.to_f / faction.nerve_refill_target.to_f) * 30, 30 ].min

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
end
