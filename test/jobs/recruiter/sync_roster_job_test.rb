require "test_helper"

class Recruiter::SyncRosterJobTest < ActiveJob::TestCase
  setup do
    Recruiter::KeyPool.stubs(:next_key).returns("pool_key")
    Recruiter::SyncRosterJob.any_instance.stubs(:sleep)
    @bert = users(:bert)
  end

  test "syncs companies, employment, and disconnects departed players" do
    users(:kaneki).update!(company_id: 91002)
    @bert.update!(faction: factions(:with_api_key))

    stub_company_snapshot([
      company_row(91001, name: "Pleasure Palace", type: 10, rating: 9, hired: 9),
      company_row(95000, name: "Fresh Corp", type: 5, rating: 3, hired: 2)
    ])
    stub_user_snapshot([
      player_row(1234567, name: "Bert", level: 51, company: 91001, faction: 46166),
      player_row(7777777, name: "Boss", level: 80, company: 91001, director: true, faction: 46166),
      player_row(5555555, name: "Newbie", level: 12, company: 95000, director: true)
    ])

    Recruiter::SyncRosterJob.perform_now

    assert_equal "Pleasure Palace", companies(:adult_novelties).reload.name
    assert_nil Company.find_by(torn_id: 91002)
    fresh = Company.find_by(torn_id: 95000)
    assert_equal 5, fresh.company_type_id
    assert_equal 3, fresh.rating

    @bert.reload
    assert_equal 51, @bert.level
    assert_equal 91001, @bert.company_id
    assert_equal 46166, @bert.faction_torn_id
    assert_equal factions(:with_api_key).id, @bert.faction_id
    assert_equal "1234567_api_token_fixture", @bert.api_token
    assert_equal 46166, companies(:adult_novelties).reload.director_faction_torn_id
    assert @bert.faction_mate_of_director?

    newbie = User.find_by(torn_id: 5555555)
    assert_equal "Newbie", newbie.name
    assert newbie.company_director
    assert_nil newbie.api_token
    assert_not newbie.faction_mate_of_director?
    assert_nil Company.find_by(torn_id: 95000).director_faction_torn_id

    assert_nil users(:kaneki).reload.company_id
  end

  test "skips when no key is available" do
    Recruiter::KeyPool.stubs(:next_key).returns(nil)
    TornApi::Company::Snapshot.any_instance.expects(:fetch).never

    Recruiter::SyncRosterJob.perform_now
  end

  private

  def company_row(torn_id, name:, type:, rating:, hired:)
    TornApi::Company::Snapshot::Row.new(
      torn_id: torn_id, name: name, company_type_id: type, rating: rating, employees_hired: hired
    )
  end

  def player_row(torn_id, name:, level:, company:, director: false, faction: nil)
    TornApi::User::Snapshot::Row.new(
      torn_id: torn_id, name: name, level: level, company_id: company, director: director, faction_torn_id: faction
    )
  end

  def stub_company_snapshot(rows)
    TornApi::Company::Snapshot.any_instance.stubs(:fetch).returns(rows)
  end

  def stub_user_snapshot(rows)
    TornApi::User::Snapshot.any_instance.stubs(:fetch).returns(rows)
  end
end
