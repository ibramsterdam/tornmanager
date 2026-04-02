require "test_helper"

class Admin::ReconControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bram = users(:bram)
    @bert = users(:bert)
    sign_in_as(@bram)
  end

  # -- Access control --

  test "requires admin" do
    sign_in_as(@bert)
    get admin_recon_path
    assert_redirected_to root_path
  end

  test "requires authentication" do
    sign_out
    get admin_recon_path
    assert_redirected_to new_session_path
  end

  # -- Show --

  test "show renders successfully" do
    get admin_recon_path
    assert_response :success
    assert_select "h1", "Recon"
  end

  test "show displays training sample count" do
    Recon::TrainingSample.create!(player_id: 1, strength: 1, defense: 1, speed: 1, dexterity: 1, spied_at: Date.today)

    get admin_recon_path
    assert_response :success
    assert_select ".recon-stat-value", /1/
  end

  test "show displays import form" do
    get admin_recon_path
    assert_select "textarea[name='spy_data']"
    assert_select "input[type='submit'][value='Import & Queue Jobs']"
  end

  test "show displays banner when import in progress" do
    Rails.cache.stubs(:read).with("recon:import_ends_at").returns(5.minutes.from_now)

    get admin_recon_path
    assert_select ".backfill-banner"
    assert_select "textarea[name='spy_data']" # form still visible
  end

  test "show displays form without banner when no import in progress" do
    get admin_recon_path
    assert_select ".backfill-banner", count: 0
    assert_select "textarea[name='spy_data']"
  end

  # -- Import --

  test "import queues jobs for valid spy data" do
    AdminCredentials.stubs(:api_key).returns("admin_key")

    spy_data = "Trole [1485341]\t78\tNone\t5,751,694,281\t7,905,360,376\t4,692,172,959\t297,478,845\t18,646,706,461\t3.00\t24/03/26"

    assert_enqueued_with(job: Recon::CollectTrainingSampleJob) do
      post import_admin_recon_path, params: { spy_data: spy_data }
    end

    assert_redirected_to admin_recon_path
    assert_match /Queued 1/, flash[:notice]
  end

  test "import queues multiple rows" do
    AdminCredentials.stubs(:api_key).returns("admin_key")

    spy_data = <<~TSV
      Trole [1485341]\t78\tNone\t5,751,694,281\t7,905,360,376\t4,692,172,959\t297,478,845\t18,646,706,461\t3.00\t24/03/26
      Dark [222379]\t50\tNone\t4,112,090,853\t3,868,907,313\t2,013,554,995\t2,001,634,998\t11,996,188,159\t3.00\t24/03/26
    TSV

    assert_enqueued_jobs 2, only: Recon::CollectTrainingSampleJob do
      post import_admin_recon_path, params: { spy_data: spy_data }
    end

    assert_match /Queued 2/, flash[:notice]
  end

  test "import rejects blank data" do
    post import_admin_recon_path, params: { spy_data: "" }
    assert_redirected_to admin_recon_path
    assert_match /No data/, flash[:alert]
  end

  test "import rejects unparseable data" do
    post import_admin_recon_path, params: { spy_data: "garbage data here" }
    assert_redirected_to admin_recon_path
    assert_match /Could not parse/, flash[:alert]
  end

  test "import writes cache timer" do
    spy_data = "Trole [1485341]\t78\tNone\t5,751,694,281\t7,905,360,376\t4,692,172,959\t297,478,845\t18,646,706,461\t3.00\t24/03/26"

    Rails.cache.expects(:write).with("recon:import_ends_at", anything, anything)

    post import_admin_recon_path, params: { spy_data: spy_data }
  end

  test "import extends existing queue by scheduling after current end" do
    existing_end = 2.minutes.from_now
    Rails.cache.stubs(:read).with("recon:import_ends_at").returns(existing_end)
    Rails.cache.stubs(:write)

    spy_data = "Trole [1485341]\t78\tNone\t5,751,694,281\t7,905,360,376\t4,692,172,959\t297,478,845\t18,646,706,461\t3.00\t24/03/26"

    assert_enqueued_with(job: Recon::CollectTrainingSampleJob) do
      post import_admin_recon_path, params: { spy_data: spy_data }
    end

    # Job should be scheduled after the existing queue ends, not from now
    job = enqueued_jobs.last
    scheduled_at = Time.parse(job["scheduled_at"])
    assert scheduled_at >= existing_end, "Job should be scheduled after existing queue ends"
  end

  test "import handles format 2 with separate rank column" do
    spy_data = "1\tPenicillin [1517799]\t100\t655,000,300,610,300\t2,761,464,594,401,500\t8,940,446,370,100\t12,344,518,438\t3,425,417,685,900,338\t30/03/26\t16 minutes ago\t81,243,777"

    assert_enqueued_with(job: Recon::CollectTrainingSampleJob) do
      post import_admin_recon_path, params: { spy_data: spy_data }
    end

    assert_match /Queued 1/, flash[:notice]
  end
end
