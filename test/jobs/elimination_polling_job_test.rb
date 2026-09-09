require "test_helper"

class EliminationPollingJobTest < ActiveJob::TestCase
  setup do
    @setting = EliminationSetting.create!(polling_active: true, api_key: "elim_key")
    @teams = [
      TornApi::Torn::Elimination::Team.new(80, "Conspiracy Theorists", 2027, 3, 1298, 48, 7900, 7500, false, nil)
    ]
  end

  test "polls, tracks, and reschedules while active" do
    TornApi::Torn::Elimination.any_instance.stubs(:fetch).returns(@teams)
    Elimination::Tracker.any_instance.expects(:process).with(@teams)

    with_memory_cache do
      assert_enqueued_with(job: EliminationPollingJob) do
        EliminationPollingJob.perform_now
      end
    end

    assert_not_nil @setting.reload.last_polled_at
  end

  test "does nothing when polling is inactive" do
    @setting.update!(polling_active: false)
    TornApi::Torn::Elimination.any_instance.expects(:fetch).never

    assert_no_enqueued_jobs do
      EliminationPollingJob.perform_now
    end
  end

  test "stops polling on an invalid key" do
    TornApi::Torn::Elimination.any_instance.stubs(:fetch).raises(TornApi::InvalidKeyError, "Invalid API key")

    with_memory_cache do
      assert_no_enqueued_jobs do
        EliminationPollingJob.perform_now
      end
    end

    assert_not @setting.reload.polling_active?
    assert_includes @setting.last_error, "Invalid API key"
  end

  test "keeps polling through transient errors and warns after repeated failures" do
    TornApi::Torn::Elimination.any_instance.stubs(:fetch).raises(TornApi::TransientError, "backend error")
    Elimination::Notifier.any_instance.expects(:health_down).once

    with_memory_cache do
      EliminationPollingJob::FAILURES_BEFORE_WARNING.times do
        EliminationPollingJob.perform_now
      end
    end

    assert @setting.reload.polling_active?
    assert_includes @setting.last_error, "backend error"
  end

  test "posts recovery after a warned outage heals" do
    with_memory_cache do
      TornApi::Torn::Elimination.any_instance.stubs(:fetch).raises(TornApi::TransientError, "backend error")
      Elimination::Notifier.any_instance.stubs(:health_down)
      EliminationPollingJob::FAILURES_BEFORE_WARNING.times { EliminationPollingJob.perform_now }

      TornApi::Torn::Elimination.any_instance.stubs(:fetch).returns(@teams)
      Elimination::Tracker.any_instance.stubs(:process)
      Elimination::Notifier.any_instance.expects(:health_recovered).once

      EliminationPollingJob.perform_now
    end
  end

  test "persists a snapshot row only when a team's numbers change" do
    changed_teams = [
      TornApi::Torn::Elimination::Team.new(80, "Conspiracy Theorists", 2027, 3, 1284, 48, 7900, 7514, false, nil)
    ]
    Elimination::Tracker.any_instance.stubs(:process)

    with_memory_cache do
      TornApi::Torn::Elimination.any_instance.stubs(:fetch).returns(@teams)
      assert_difference "EliminationSnapshot.count", 1 do
        EliminationPollingJob.perform_now
        EliminationPollingJob.perform_now
      end

      TornApi::Torn::Elimination.any_instance.stubs(:fetch).returns(changed_teams)
      assert_difference "EliminationSnapshot.count", 1 do
        EliminationPollingJob.perform_now
      end
    end
  end

  test "start_polling! enqueues and stop_polling! halts the loop" do
    @setting.update!(polling_active: false)

    assert_enqueued_with(job: EliminationPollingJob) do
      @setting.start_polling!
    end
    assert @setting.reload.polling_active?

    @setting.stop_polling!
    assert_not @setting.reload.polling_active?
  end

  private

  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original_cache
  end
end
