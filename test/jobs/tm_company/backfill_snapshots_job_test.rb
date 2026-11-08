require "test_helper"

class TmCompany::BackfillSnapshotsJobTest < ActiveJob::TestCase
  setup do
    Recruiter::KeyPool.stubs(:next_key).returns("pool_key")
    TmCompany::BackfillSnapshotsJob.any_instance.stubs(:sleep)
  end

  test "fills missing days until torn has no older file" do
    CompanySnapshot.create!(company_torn_id: 91001, date: Date.current - 2, company_type_id: 10, rating: 9)
    fetched = []
    TornApi::Company::Snapshot.stubs(:new).with do |key, options|
      fetched << options[:timestamp].to_date
      key == "pool_key" && options[:comment] == "tmcompany"
    end.returns(snapshot_returning([ row(91001) ]), snapshot_returning([ row(91001) ]), snapshot_raising)

    TmCompany::BackfillSnapshotsJob.perform_now(10)

    assert_equal [ Date.current - 1, Date.current - 3, Date.current - 4 ], fetched
    assert_equal [ Date.current - 3, Date.current - 2, Date.current - 1 ],
      CompanySnapshot.where(company_torn_id: 91001).order(:date).pluck(:date)
  end

  test "skips when no key is available" do
    Recruiter::KeyPool.stubs(:next_key).returns(nil)
    TornApi::Company::Snapshot.expects(:new).never

    TmCompany::BackfillSnapshotsJob.perform_now
  end

  private

  def row(torn_id)
    TornApi::Company::Snapshot::Row.new(
      torn_id: torn_id, name: "Co", company_type_id: 10, rating: 9, employees_hired: 5,
      employees_capacity: 5, daily_income: 1_000, daily_customers: 1, weekly_income: 7_000, weekly_customers: 7
    )
  end

  def snapshot_returning(rows)
    stub(fetch: rows)
  end

  def snapshot_raising
    snapshot = stub
    snapshot.stubs(:fetch).raises(TornApi::NotFoundError, "File does not exist")
    snapshot
  end
end
