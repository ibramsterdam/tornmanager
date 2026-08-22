require "test_helper"

class Admin::RecruiterControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @admin = users(:bram)
    sign_in_as(@admin)
  end

  test "requires admin access" do
    sign_in_as(users(:bert))
    get admin_recruiter_path
    assert_redirected_to root_path
  end

  test "renders the shell with a lazy frame per section" do
    get admin_recruiter_path

    assert_response :success
    %w[pipeline jobs keys ratings].each do |name|
      assert_select "turbo-frame#recruiter-#{name}[src=?]", admin_recruiter_section_path(name: name)
    end
  end

  test "every section renders" do
    %w[pipeline jobs keys ratings].each do |name|
      get admin_recruiter_section_path(name: name)
      assert_response :success
    end
  end

  test "unknown sections are not found" do
    get admin_recruiter_section_path(name: "everything")
    assert_response :not_found
  end

  test "shows the idle warning without any keys" do
    get admin_recruiter_section_path(name: "pipeline")

    assert_response :success
    assert_match "pipeline idle", response.body
  end

  test "lists consented pool keys with owner and submitter" do
    api_keys(:bram_personal_key).update!(recruiter_fetch_allowed: true, submitted_by: @admin)

    get admin_recruiter_section_path(name: "keys")

    assert_response :success
    assert_match "ABCD", response.body
    assert_match "Bram [2728237]", response.body

    get admin_recruiter_section_path(name: "pipeline")
    assert_no_match "pipeline idle", response.body
  end

  test "run enqueues the requested job" do
    assert_enqueued_with(job: Recruiter::SyncRosterJob) do
      post admin_recruiter_run_path(job: "sync_roster")
    end
    assert_redirected_to admin_recruiter_path
  end

  test "run rejects unknown jobs" do
    assert_no_enqueued_jobs do
      post admin_recruiter_run_path(job: "everything")
    end
    assert_redirected_to admin_recruiter_path
  end
end
