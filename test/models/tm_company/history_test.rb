require "test_helper"

class TmCompany::HistoryTest < ActiveSupport::TestCase
  test "lines up income, peers and captured data by date" do
    yesterday = Date.current - 1
    CompanySnapshot.create!(company_torn_id: 127301, date: yesterday, company_type_id: 28, rating: 7, employees_hired: 10, daily_income: 50_000_000, daily_customers: 3)
    CompanySnapshot.create!(company_torn_id: 1, date: yesterday, company_type_id: 28, rating: 7, employees_hired: 10, daily_income: 30_000_000)
    captured_day(date: yesterday)

    json = TmCompany::History.new(127301, days: 7).as_json

    assert_equal 7, json[:dates].size
    assert_equal Date.current, json[:dates].last
    index = json[:dates].index(yesterday)
    assert_equal 50_000_000, json[:series][:income][index]
    assert_equal 5_000_000, json[:series][:income_per_employee][index]
    assert_equal 5_000_000, json[:series][:peer_top_per_employee][index]
    assert_equal 27_750_000, json[:series][:wages][index]
    assert_equal 84, json[:series][:environment][index]
    assert json[:series][:effectiveness][index].positive?
    assert_nil json[:series][:income][json[:dates].index(Date.current)]
  end
end
