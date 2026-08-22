require "test_helper"

class TornApi::User::SnapshotTest < ActiveSupport::TestCase
  setup do
    @service = TornApi::User::Snapshot.new("test_key")
  end

  test "keeps only employed players" do
    csv = <<~CSV
      id,name,level,company,job
      1234567,Bert,50,91001,Employee
      2728237,Bram,69,0,None
      7777777,Boss,80,91001,Director
      8888888,Drifter,12,,None
    CSV
    @service.expects(:get).with("v2/user/snapshot", { comment: "tmrecruiter" }).returns(csv)

    rows = @service.fetch

    assert_equal [ 1234567, 7777777 ], rows.map(&:torn_id)
    bert = rows.first
    assert_equal "Bert", bert.name
    assert_equal 50, bert.level
    assert_equal 91001, bert.company_id
    assert_not bert.director
    assert rows.last.director
  end

  test "raises when the response is not csv" do
    @service.expects(:get).returns({ "unexpected" => true })

    assert_raises(TornApi::ApiError) { @service.fetch }
  end
end
