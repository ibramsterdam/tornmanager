require "test_helper"

class TornApi::User::SnapshotTest < ActiveSupport::TestCase
  setup do
    @service = TornApi::User::Snapshot.new("test_key")
  end

  test "keeps only employed players" do
    csv = <<~CSV
      id,name,gender,level,rank,faction,company,job
      1234567,Bert,Male,50,Elite,46166,91001,
      2728237,Bram,Male,69,Elite,,0,
      7777777,Boss,Female,80,Elite,9118,91001,Director
      8888888,Drifter,Male,12,Amateur,,,Army
    CSV
    @service.expects(:get).with("v2/user/snapshot", { comment: "tmrecruiter" }).returns(csv)

    rows = @service.fetch

    assert_equal [ 1234567, 7777777 ], rows.map(&:torn_id)
    bert = rows.first
    assert_equal "Bert", bert.name
    assert_equal 50, bert.level
    assert_equal 91001, bert.company_id
    assert_equal 46166, bert.faction_torn_id
    assert_not bert.director
    assert rows.last.director
  end

  test "leaves faction empty for factionless players" do
    csv = <<~CSV
      id,name,gender,level,rank,faction,company,job
      1234567,Bert,Male,50,Elite,,91001,
    CSV
    @service.expects(:get).returns(csv)

    assert_nil @service.fetch.first.faction_torn_id
  end

  test "raises when the response is not csv" do
    @service.expects(:get).returns({ "unexpected" => true })

    assert_raises(TornApi::ApiError) { @service.fetch }
  end
end
