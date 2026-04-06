class Faction < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :faction_subscription_grants, dependent: :nullify
  has_many :ranked_wars, dependent: :destroy
  has_one :faction_setting, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_one :torn_api_key, class_name: "ApiKey::Torn"
  has_one :tornstats_api_key, class_name: "ApiKey::Tornstats"
  has_many :api_calls, dependent: :nullify
  has_many :spy_reports, dependent: :destroy

  has_many :armory_news_entries, dependent: :destroy
  has_many :member_activity_snapshots, dependent: :destroy
  has_many :leadership, -> { where(leadership_access: true) }, class_name: "User"
  has_one :subscription, as: :subscribable, dependent: :destroy

  validates :torn_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :xanax_target, presence: true, numericality: { greater_than: 0 }
  validates :energy_refill_target, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :nerve_refill_target, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def to_param
    torn_id.to_s
  end

  def member_count
    users.count
  end

  def backfill_in_progress?
    backfill_ends_at.present? && backfill_ends_at > Time.current
  end

  def backfill_seconds_remaining
    return 0 unless backfill_in_progress?
    (backfill_ends_at - Time.current).to_i
  end

  def clear_backfill_status!
    update!(backfill_ends_at: nil, backfill_target_date: nil)
  end

  def current_war
    ranked_wars.ongoing.order(started_at: :desc).first
  end

  def start_war_polling!
    update!(war_polling_active: true)
    WarPollingJob.perform_later(id)
  end

  def stop_war_polling!
    update!(war_polling_active: false)
    Rails.cache.delete(war_cache_key)
  end

  def war_cache_key
    "faction:#{id}:war_data"
  end

  def leadership?(user)
    return false unless user
    user.faction_id == id && user.leadership_access?
  end

  def import_spy_report(spy)
    report = spy_reports.find_or_initialize_by(torn_id: spy.torn_id)
    report.assign_attributes(
      strength: spy.strength,
      defense: spy.defense,
      speed: spy.speed,
      dexterity: spy.dexterity,
      total: spy.total,
      spied_at: spy.spied_at
    )
    report.save!
  end

  def delete_all_data!
    transaction do
      stop_war_polling! if war_polling_active?
      clear_backfill_status! if backfill_in_progress?

      user_ids = users.pluck(:id)
      PersonalStatSnapshot.where(user_id: user_ids).delete_all if user_ids.any?
      spy_reports.delete_all
      ranked_wars.delete_all

      armory_news_entries.delete_all
      member_activity_snapshots.delete_all
      users.update_all(leadership_access: false)
      api_keys.destroy_all
      faction_setting&.destroy!
      update!(setup_completed: false)

      cancel_background_jobs(user_ids)
    end
  end

  private

  def cancel_background_jobs(user_ids)
    SolidQueue::Job
      .where(finished_at: nil)
      .where(class_name: %w[
        BackfillArmoryNewsJob
        BackfillPersonalStatsJob
        BackfillRankedWarsJob
        ClearBackfillStatusJob
        FetchArmoryNewsJob
        WarPollingJob
      ])
      .where("arguments LIKE ?", "%\"arguments\":[#{id},%")
      .destroy_all

    if user_ids.any?
      SolidQueue::Job
        .where(finished_at: nil)
        .where(class_name: %w[BackfillSingleStatJob BackfillUserStatsJob])
        .where(user_ids.map { |uid| "arguments LIKE '%\"arguments\":[#{uid},%'" }.join(" OR "))
        .destroy_all
    end

    SolidQueue::Semaphore.where(key: "war_polling_faction_#{id}").delete_all
  rescue => e
    Rails.logger.warn("Failed to cancel faction jobs for faction #{torn_id}: #{e.class} - #{e.message}")
  end
end
