require "test_helper"

class HallOfFamersHelperTest < ActionView::TestCase
  include HallOfFamersHelper

  test "user_stats_clipboard_text formats all stats" do
    row = {
      name: "Kaneki",
      xanax_gained: 50,
      xanax_daily: 4.55,
      energy_drinks_gained: 25,
      energy_drinks_daily: 2.27,
      se_gained: 30,
      se_daily: 2.73,
      total_se: 230,
      networth_gained: 1_000_000,
      networth_daily: 90909,
      days_tracked: 11
    }

    text = user_stats_clipboard_text(row, start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 11), days: 11)

    assert_includes text, "From 01 Jan 2026 to 11 Jan 2026 (11 days) Kaneki has:"
    assert_includes text, "- Used 50 xanax (4.55/day)"
    assert_includes text, "- Used 25 energy drinks (2.27/day)"
    assert_includes text, "- Used 30 stat enhancers (2.73/day, 230 total)"
    assert_includes text, "- Networth change: $1,000,000 ($90,909/day)"
  end

  test "user_stats_clipboard_text formats large numbers with delimiters" do
    row = {
      name: "TestUser",
      xanax_gained: 1_500,
      xanax_daily: 10.0,
      energy_drinks_gained: 800,
      energy_drinks_daily: 5.33,
      se_gained: 2_000,
      se_daily: 13.33,
      total_se: 10_000,
      networth_gained: 50_000_000,
      networth_daily: 333_333,
      days_tracked: 150
    }

    text = user_stats_clipboard_text(row, start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 5, 31), days: 150)

    assert_includes text, "1,500 xanax"
    assert_includes text, "2,000 stat enhancers"
    assert_includes text, "10,000 total"
    assert_includes text, "$50,000,000"
  end
end
