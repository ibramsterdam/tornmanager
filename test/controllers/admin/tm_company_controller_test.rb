require "test_helper"

class Admin::TmCompanyControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    sign_in_as(users(:bram))
    @director = tracked_director
  end

  test "requires admin access" do
    sign_in_as(users(:bert))

    get admin_tm_company_path

    assert_redirected_to root_path
  end

  test "lists directors with a key" do
    CompanyDay.create!(company_torn_id: 127301, date: Date.current, captured_at: 2.hours.ago, user: @director)

    get admin_tm_company_path

    assert_response :success
    assert_select "td", text: /Bert \[1234567\]/
    assert_select "td", text: /about 2 hours ago/
    assert_select "td.success", text: /active/
  end

  test "turns access off and on" do
    patch admin_tm_company_toggle_access_path(@director)

    assert @director.reload.company_access_disabled?

    patch admin_tm_company_toggle_access_path(@director)

    assert_not @director.reload.company_access_disabled?
  end

  test "runs the capture and the backfill" do
    post admin_tm_company_run_path(job: "capture_all")
    assert_enqueued_with(job: TmCompany::CaptureAllJob)

    post admin_tm_company_run_path(job: "backfill_snapshots")
    assert_enqueued_with(job: TmCompany::BackfillSnapshotsJob)
  end

  test "rejects unknown jobs" do
    post admin_tm_company_run_path(job: "drop_tables")

    assert_redirected_to admin_tm_company_path
    assert_equal "Unknown job.", flash[:alert]
  end
end
