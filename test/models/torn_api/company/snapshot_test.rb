require "test_helper"

class TornApi::Company::SnapshotTest < ActiveSupport::TestCase
  setup do
    @service = TornApi::Company::Snapshot.new("test_key")
  end

  test "parses the company snapshot csv" do
    csv = <<~CSV
      id,name,type,rating,employees_hired
      91001,"Pleasure, Dome",10,9,8
      91002,Prime Time,26,10,12
    CSV
    @service.expects(:get).with("v2/company/snapshot", { comment: "tmrecruiter" }).returns(csv)

    rows = @service.fetch

    assert_equal 2, rows.size
    first = rows.first
    assert_equal 91001, first.torn_id
    assert_equal "Pleasure, Dome", first.name
    assert_equal 10, first.company_type_id
    assert_equal 9, first.rating
    assert_equal 8, first.employees_hired
  end

  test "parses income, customers and capacity" do
    csv = <<~CSV
      id,name,created_at,days_old,image,type,rating,director_id,employees_hired,employees_capacity,daily_income,daily_customers,weekly_income,weekly_customers,applications_allowed
      127301,"Crude Awakening [HIRING]",1783361714,124,x.png,28,7,3152867,18,18,92671990,3,666855894,21,1
    CSV
    @service.expects(:get).returns(csv)

    row = @service.fetch.first

    assert_equal 18, row.employees_capacity
    assert_equal 92_671_990, row.daily_income
    assert_equal 3, row.daily_customers
    assert_equal 666_855_894, row.weekly_income
    assert_equal 21, row.weekly_customers
  end

  test "asks for an earlier day with a timestamp" do
    at = Time.utc(2026, 10, 9, 12)
    service = TornApi::Company::Snapshot.new("test_key", timestamp: at, comment: "tmcompany")
    service.expects(:get).with("v2/company/snapshot", { comment: "tmcompany", timestamp: at.to_i }).returns("id,name,type,rating,employees_hired\n")

    assert_equal [], service.fetch
  end

  test "raises when the response is not csv" do
    @service.expects(:get).returns({ "unexpected" => true })

    assert_raises(TornApi::ApiError) { @service.fetch }
  end

  test "parse_body passes csv through and decodes json errors" do
    assert_equal "id,name\n1,x\n", @service.send(:parse_body, "id,name\n1,x\n")
    assert_equal({ "error" => { "code" => 2 } }, @service.send(:parse_body, '{"error":{"code":2}}'))
  end

  test "parse_body relabels binary bodies as utf-8" do
    parsed = @service.send(:parse_body, "id,name\n1,Caf\u00e9 \u2605\n".b)

    assert_equal Encoding::UTF_8, parsed.encoding
    assert_includes parsed, "Café ★"
  end
end
