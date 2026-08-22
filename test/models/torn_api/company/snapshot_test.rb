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
