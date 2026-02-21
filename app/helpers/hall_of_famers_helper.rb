module HallOfFamersHelper
  def user_stats_clipboard_text(row, start_date:, end_date:, days:)
    formatted_start = start_date.strftime("%d %b %Y")
    formatted_end = end_date.strftime("%d %b %Y")

    lines = []
    lines << "From #{formatted_start} to #{formatted_end} (#{days} days) #{row[:name]} has:"
    lines << "- Used #{number_with_delimiter(row[:xanax_gained])} xanax (#{row[:xanax_daily]}/day)"
    lines << "- Used #{number_with_delimiter(row[:energy_drinks_gained])} energy drinks (#{row[:energy_drinks_daily]}/day)"
    lines << "- Used #{number_with_delimiter(row[:se_gained])} stat enhancers (#{row[:se_daily]}/day, #{number_with_delimiter(row[:total_se])} total)"
    lines << "- Networth change: #{number_to_currency(row[:networth_gained], precision: 0)} (#{number_to_currency(row[:networth_daily], precision: 0)}/day)"
    lines.join("\n")
  end
end
