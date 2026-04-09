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

  test "import creates sample and queues job" do
    spy_data = "Trole [1485341]\t78\tNone\t5,751,694,281\t7,905,360,376\t4,692,172,959\t297,478,845\t18,646,706,461\t3.00\t24/03/26"

    assert_difference "Recon::TrainingSample.count", 1 do
      assert_enqueued_with(job: Recon::CollectTrainingSampleJob) do
        post import_admin_recon_path, params: { spy_data: spy_data }
      end
    end

    sample = Recon::TrainingSample.last
    assert_equal 1485341, sample.player_id
    assert_equal 5_751_694_281, sample.strength
    assert_nil sample.xantaken # features not yet collected

    assert_redirected_to admin_recon_path
    assert_match /Queued 1/, flash[:notice]
  end

  test "import queues multiple rows" do
    spy_data = <<~TSV
      Trole [1485341]\t78\tNone\t5,751,694,281\t7,905,360,376\t4,692,172,959\t297,478,845\t18,646,706,461\t3.00\t24/03/26
      Dark [222379]\t50\tNone\t4,112,090,853\t3,868,907,313\t2,013,554,995\t2,001,634,998\t11,996,188,159\t3.00\t24/03/26
    TSV

    assert_difference "Recon::TrainingSample.count", 2 do
      assert_enqueued_jobs 2, only: Recon::CollectTrainingSampleJob do
        post import_admin_recon_path, params: { spy_data: spy_data }
      end
    end

    assert_match /Queued 2/, flash[:notice]
  end

  test "import skips rows already in database" do
    Recon::TrainingSample.create!(
      player_id: 1485341, strength: 1, defense: 1, speed: 1, dexterity: 1,
      spied_at: Date.new(2026, 3, 24)
    )

    spy_data = "Trole [1485341]\t78\tNone\t5,751,694,281\t7,905,360,376\t4,692,172,959\t297,478,845\t18,646,706,461\t3.00\t24/03/26"

    assert_no_enqueued_jobs(only: Recon::CollectTrainingSampleJob) do
      post import_admin_recon_path, params: { spy_data: spy_data }
    end

    assert_match /already collected/, flash[:notice]
  end

  test "import skips existing and queues new rows" do
    Recon::TrainingSample.create!(
      player_id: 1485341, strength: 1, defense: 1, speed: 1, dexterity: 1,
      spied_at: Date.new(2026, 3, 24)
    )

    spy_data = <<~TSV
      Trole [1485341]\t78\tNone\t5,751,694,281\t7,905,360,376\t4,692,172,959\t297,478,845\t18,646,706,461\t3.00\t24/03/26
      Dark [222379]\t50\tNone\t4,112,090,853\t3,868,907,313\t2,013,554,995\t2,001,634,998\t11,996,188,159\t3.00\t24/03/26
    TSV

    assert_enqueued_jobs 1, only: Recon::CollectTrainingSampleJob do
      post import_admin_recon_path, params: { spy_data: spy_data }
    end

    assert_match /Queued 1/, flash[:notice]
    assert_match /1 already collected/, flash[:notice]
  end

  test "import does not extend timer when all rows skipped" do
    Recon::TrainingSample.create!(
      player_id: 1485341, strength: 1, defense: 1, speed: 1, dexterity: 1,
      spied_at: Date.new(2026, 3, 24), level: 78
    )

    Rails.cache.expects(:write).with("recon:import_ends_at", anything, anything).never

    spy_data = "Trole [1485341]\t78\tNone\t5,751,694,281\t7,905,360,376\t4,692,172,959\t297,478,845\t18,646,706,461\t3.00\t24/03/26"
    post import_admin_recon_path, params: { spy_data: spy_data }
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

  test "import extends existing queue timer" do
    existing_end = 2.minutes.from_now
    Rails.cache.stubs(:read).with("recon:import_ends_at").returns(existing_end)
    Rails.cache.stubs(:write)

    spy_data = "Trole [1485341]\t78\tNone\t5,751,694,281\t7,905,360,376\t4,692,172,959\t297,478,845\t18,646,706,461\t3.00\t24/03/26"

    assert_enqueued_with(job: Recon::CollectTrainingSampleJob) do
      post import_admin_recon_path, params: { spy_data: spy_data }
    end

    job = enqueued_jobs.last
    scheduled_at = Time.parse(job["scheduled_at"])
    assert scheduled_at >= existing_end, "Job should be scheduled after existing queue ends"
  end

  # -- Predict --

  test "predict returns estimation for valid torn id" do
    AdminCredentials.stubs(:api_key).returns("test_key")
    Recon::TornApi::PersonalStats.any_instance.stubs(:fetch).returns({
      "xantaken" => 1000, "energydrinkused" => 50, "refills" => 200,
      "daysbeendonator" => 500, "statenhancersused" => 0, "boostersused" => 100,
      "lsdtaken" => 0, "revives" => 5, "exttaken" => 10, "victaken" => 3,
      "rehabs" => 50, "highestbeaten" => 80, "hospital" => 200,
      "jobpointsused" => 5000, "trainsreceived" => 300, "attackswon" => 1000,
      "awards" => 200, "timeplayed" => 1000000, "networth" => 5_000_000_000
    })
    Recon::TornApi::Profile.any_instance.stubs(:fetch).returns(
      Recon::TornApi::Profile::ProfileData.new(age: 1000, level: 80, property: "Private Island", last_action_timestamp: Time.now.to_i)
    )
    Recon::Predictor.stubs(:trained?).returns(true)
    Recon::Predictor.any_instance.stubs(:predict).returns(2_500_000_000)

    post predict_admin_recon_path, params: { torn_id: "12345" }, as: :turbo_stream
    assert_response :success
  end

  test "predict returns error for blank torn id" do
    post predict_admin_recon_path, params: { torn_id: "" }, as: :turbo_stream
    assert_response :success
    assert_match /Please enter a Torn ID/, response.body
  end

  test "predict returns error when admin key not configured" do
    AdminCredentials.stubs(:api_key).returns(nil)

    post predict_admin_recon_path, params: { torn_id: "12345" }, as: :turbo_stream
    assert_response :success
    assert_match /Admin API key not configured/, response.body
  end

  test "predict returns error when model not trained" do
    AdminCredentials.stubs(:api_key).returns("test_key")
    Recon::Predictor.stubs(:trained?).returns(false)

    post predict_admin_recon_path, params: { torn_id: "12345" }, as: :turbo_stream
    assert_response :success
    assert_match /Model not trained/, response.body
  end

  test "predict handles API errors gracefully" do
    AdminCredentials.stubs(:api_key).returns("test_key")
    Recon::Predictor.stubs(:trained?).returns(true)
    Recon::TornApi::PersonalStats.any_instance.stubs(:fetch).raises(TornApi::ApiError, "something broke")

    post predict_admin_recon_path, params: { torn_id: "12345" }, as: :turbo_stream
    assert_response :success
    assert_match /API error/, response.body
  end

  # -- Quick Add --

  test "quick_add creates sample and queues job" do
    assert_difference "Recon::TrainingSample.count", 1 do
      assert_enqueued_with(job: Recon::CollectTrainingSampleJob) do
        post quick_add_admin_recon_path, params: {
          torn_id: "999999", strength: "1,000,000", defense: "2,000,000",
          speed: "500,000", dexterity: "500,000"
        }
      end
    end

    sample = Recon::TrainingSample.last
    assert_equal 999999, sample.player_id
    assert_equal 1_000_000, sample.strength
    assert_equal 2_000_000, sample.defense
    assert_equal 500_000, sample.speed
    assert_equal 500_000, sample.dexterity
    assert_equal Date.current, sample.spied_at

    assert_redirected_to admin_recon_path
    assert_match /Added sample for 999999/, flash[:notice]
  end

  test "quick_add strips non-numeric characters from stats" do
    post quick_add_admin_recon_path, params: {
      torn_id: "999999", strength: "1,083,136,138", defense: "1,197,787,103",
      speed: "593,848,799", dexterity: "13,731"
    }

    sample = Recon::TrainingSample.last
    assert_equal 1_083_136_138, sample.strength
    assert_equal 1_197_787_103, sample.defense
    assert_equal 593_848_799, sample.speed
    assert_equal 13_731, sample.dexterity
  end

  test "quick_add updates existing sample for same player and date" do
    Recon::TrainingSample.create!(
      player_id: 999999, strength: 1, defense: 1, speed: 1, dexterity: 1,
      spied_at: Date.current
    )

    assert_no_difference "Recon::TrainingSample.count" do
      post quick_add_admin_recon_path, params: {
        torn_id: "999999", strength: "2000000", defense: "3000000",
        speed: "1000000", dexterity: "1000000"
      }
    end

    sample = Recon::TrainingSample.find_by(player_id: 999999, spied_at: Date.current)
    assert_equal 2_000_000, sample.strength
  end

  test "quick_add rejects blank torn id" do
    assert_no_difference "Recon::TrainingSample.count" do
      post quick_add_admin_recon_path, params: {
        torn_id: "", strength: "1000", defense: "1000", speed: "1000", dexterity: "1000"
      }
    end

    assert_redirected_to admin_recon_path
    assert_match /required/, flash[:alert]
  end

  test "quick_add rejects zero stats" do
    assert_no_difference "Recon::TrainingSample.count" do
      post quick_add_admin_recon_path, params: {
        torn_id: "999999", strength: "0", defense: "0", speed: "0", dexterity: "0"
      }
    end

    assert_redirected_to admin_recon_path
    assert_match /required/, flash[:alert]
  end

  test "import handles format 2 with separate rank column" do
    spy_data = "1\tPenicillin [1517799]\t100\t655,000,300,610,300\t2,761,464,594,401,500\t8,940,446,370,100\t12,344,518,438\t3,425,417,685,900,338\t30/03/26\t16 minutes ago\t81,243,777"

    assert_difference "Recon::TrainingSample.count", 1 do
      assert_enqueued_with(job: Recon::CollectTrainingSampleJob) do
        post import_admin_recon_path, params: { spy_data: spy_data }
      end
    end

    assert_match /Queued 1/, flash[:notice]
  end
end
