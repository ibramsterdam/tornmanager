require "test_helper"

class TmCompany::ReportTest < ActiveSupport::TestCase
  setup do
    stub_company_types
    @day = captured_day
  end

  test "summarises the company" do
    company = report.company

    assert_equal "Oil Rig", company[:type_name]
    assert_equal 92_671_990, company[:income_daily]
    assert_equal 27_750_000, company[:wages_daily]
    assert_equal 92_671_990 - 27_750_000, company[:profit_daily]
    assert_equal 12, company[:trains]
  end

  test "flags employees that need attention" do
    rows = report.employee_rows.index_by { |row| row[:name] }

    assert_includes rows["Employee3"][:flags], "below_requirement"
    assert_includes rows["Employee4"][:flags], "addicted"
    assert_includes rows["Employee5"][:flags], "inactive"
    assert_empty rows["Employee1"][:flags]
    assert_equal({ "intelligence" => 75000, "manual_labor" => 150000, "endurance" => 0 }, rows["Employee1"][:required])
  end

  test "counts staff per position and finds missing abilities" do
    balance = report.balance

    assert_equal 7, balance[:positions].size
    assert_equal 0, balance[:positions].find { |position| position[:name] == "Inspector" }[:count]
    assert_includes balance[:missing_abilities], "Trainer"
  end

  test "compares income per employee with companies of the same type and stars" do
    CompanySnapshot.create!(company_torn_id: 127301, date: Date.current, company_type_id: 28, rating: 7, employees_hired: 18, daily_income: 92_671_990)
    CompanySnapshot.create!(company_torn_id: 1, date: Date.current, company_type_id: 28, rating: 7, employees_hired: 10, daily_income: 30_000_000)
    CompanySnapshot.create!(company_torn_id: 2, date: Date.current, company_type_id: 28, rating: 7, employees_hired: 10, daily_income: 120_000_000)
    CompanySnapshot.create!(company_torn_id: 3, date: Date.current, company_type_id: 28, rating: 8, employees_hired: 10, daily_income: 900_000_000)

    benchmark = report.benchmark

    assert_equal 3, benchmark[:peers]
    assert_equal 2, benchmark[:rank]
    assert_equal 5_148_443, benchmark[:income_per_employee]
    assert_equal 5_148_443, benchmark[:median_per_employee]
    assert_equal 12_000_000, benchmark[:top_per_employee]
  end

  test "advises on the missing trainer and flagged staff" do
    titles = report.advice.map { |item| item[:title] }

    assert_includes titles, "No Inspector on staff"
    assert_includes titles, "1 employee addicted"
    assert_includes titles, "1 employee inactive"
  end

  test "warns when trains are full and stock runs low" do
    @day.update!(
      detailed: tm_company_fixture("detailed").merge("trains_available" => 20),
      stock: [ tm_company_fixture("stock").first.merge("in_stock" => 1000, "sold_amount" => 2200) ]
    )

    titles = report.advice.map { |item| item[:title] }

    assert_includes titles, "Trains are full"
    assert_includes titles, "Oil (Barrel) runs out soon"
  end

  test "points out empty slots" do
    @day.update!(profile: tm_company_fixture("profile").merge("employees" => { "hired" => 16, "capacity" => 18 }))

    item = report.advice.find { |advice| advice[:title] == "2 empty slots" }

    assert_match "about $", item[:detail]
  end

  test "works with a public style capture without stats or wages" do
    employees = tm_company_fixture("employees").map { |employee| employee.except("stats", "effectiveness", "wage", "value") }
    @day.update!(employees: employees, stock: nil, detailed: nil)

    json = report.as_json

    assert_nil json[:company][:wages_daily]
    assert_nil json[:company][:profit_daily]
    assert_equal 6, json[:employees].size
    assert_empty json[:stock]
  end

  private

  def report
    TmCompany::Report.new(@day.reload)
  end
end
