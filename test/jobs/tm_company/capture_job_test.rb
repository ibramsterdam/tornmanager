require "test_helper"

class TmCompany::CaptureJobTest < ActiveJob::TestCase
  setup do
    TmCompany::CaptureJob.any_instance.stubs(:sleep)
    @user = tracked_director
    TornApi::User::Job.any_instance.stubs(:fetch).returns(director_job)
    TornApi::Company::Director.any_instance.stubs(:profile).returns(tm_company_fixture("profile"))
    TornApi::Company::Director.any_instance.stubs(:employees).returns(tm_company_fixture("employees"))
    TornApi::Company::Director.any_instance.stubs(:stock).returns(tm_company_fixture("stock"))
    TornApi::Company::Director.any_instance.stubs(:detailed).returns(tm_company_fixture("detailed"))
    TornApi::Company::Director.any_instance.stubs(:news).returns([
      { "id" => "n1", "text" => "Joe trained Employee1", "timestamp" => 1.hour.ago.to_i }
    ])
  end

  test "stores today's company data and news" do
    TmCompany::CaptureJob.perform_now(@user.id)

    day = CompanyDay.find_by!(company_torn_id: 127301, date: Date.current)
    assert_equal @user, day.user
    assert_equal 92_671_990, day.profile.dig("income", "daily")
    assert_equal 6, day.employees.size
    assert_equal 5400, day.stock.first["in_stock"]
    assert_equal 12, day.detailed["trains_available"]
    assert_equal [ "n1" ], CompanyNewsEntry.where(company_torn_id: 127301).pluck(:news_id)
  end

  test "overwrites today's row when it runs again" do
    TmCompany::CaptureJob.perform_now(@user.id)
    TmCompany::CaptureJob.perform_now(@user.id)

    assert_equal 1, CompanyDay.where(company_torn_id: 127301).count
    assert_equal 1, CompanyNewsEntry.count
  end

  test "asks for news after the newest stored entry" do
    newest = 2.days.ago.change(usec: 0)
    CompanyNewsEntry.create!(company_torn_id: 127301, news_id: "old", occurred_at: newest, text: "x")
    TornApi::Company::Director.any_instance.expects(:news).with(since: newest).returns([])

    TmCompany::CaptureJob.perform_now(@user.id)
  end

  test "still stores the day when stock and detailed are not available" do
    TornApi::Company::Director.any_instance.stubs(:stock).raises(TornApi::NotFoundError, "Incorrect ID")
    TornApi::Company::Director.any_instance.stubs(:detailed).raises(TornApi::ApiError, "Wrong fields requested")

    TmCompany::CaptureJob.perform_now(@user.id)

    day = CompanyDay.find_by!(company_torn_id: 127301)
    assert_nil day.stock
    assert_nil day.detailed
    assert_equal 6, day.employees.size
  end

  test "stops tracking someone who is no longer the director" do
    TornApi::User::Job.any_instance.stubs(:fetch).returns(director_job(position: "Driller"))
    TornApi::Company::Director.any_instance.expects(:profile).never

    TmCompany::CaptureJob.perform_now(@user.id)

    assert_not @user.reload.company_director?
    assert_not CompanyDay.exists?
  end

  test "follows the director to a new company" do
    TornApi::User::Job.any_instance.stubs(:fetch).returns(director_job(company_id: 130000))

    TmCompany::CaptureJob.perform_now(@user.id)

    assert_equal 130000, @user.reload.company_id
    assert CompanyDay.exists?(company_torn_id: 130000)
  end

  test "gives up quietly when the key stopped working" do
    TornApi::User::Job.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "Access level of this key is not high enough")

    assert_nothing_raised { TmCompany::CaptureJob.perform_now(@user.id) }
    assert_not CompanyDay.exists?
  end

  test "skips users without access" do
    @user.update!(company_access_disabled: true)
    TornApi::User::Job.any_instance.expects(:fetch).never

    TmCompany::CaptureJob.perform_now(@user.id)
  end

  test "the daily run queues a capture for every tracked director" do
    other = tracked_director(users(:kaneki), company_id: 130000)
    users(:user_no_faction).update!(company_director: true)

    TmCompany::CaptureAllJob.perform_now

    assert_enqueued_with(job: TmCompany::CaptureJob, args: [ @user.id ])
    assert_enqueued_with(job: TmCompany::CaptureJob, args: [ other.id ])
    assert_enqueued_jobs 2, only: TmCompany::CaptureJob
  end
end
