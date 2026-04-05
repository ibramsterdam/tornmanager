class RankedWar < ApplicationRecord
  belongs_to :faction
  has_many :ranked_war_attacks, dependent: :destroy

  scope :completed, -> { where.not(ended_at: nil) }
  scope :ongoing, -> { where(ended_at: nil) }
  scope :won, -> { completed.joins(:faction).where("winner_faction_id = factions.torn_id") }
  scope :lost, -> { completed.joins(:faction).where("winner_faction_id != factions.torn_id AND winner_faction_id IS NOT NULL") }
  scope :recent, -> { order(started_at: :desc) }

  def to_param
    torn_war_id.to_s
  end

  def ongoing?
    ended_at.nil?
  end

  def completed?
    ended_at.present?
  end

  def scheduled?
    ongoing? && started_at > Time.current
  end

  def in_progress?
    ongoing? && started_at <= Time.current
  end

  def won?
    completed? && winner_faction_id == faction.torn_id
  end

  def lost?
    completed? && winner_faction_id.present? && winner_faction_id != faction.torn_id
  end

  def starts_in_seconds
    return 0 unless scheduled?
    (started_at - Time.current).to_i
  end

  def duration
    return nil if ongoing?
    ended_at - started_at
  end

  def duration_formatted
    return "Ongoing" if ongoing?

    seconds = duration.to_i
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end

  def rank_change
    return nil unless rank_before.present? && rank_after.present?
    "→"
  end

  def our_participating_members
    our_members.select { |m| m["attacks"].to_i > 0 }
  end

  def their_participating_members
    their_members.select { |m| m["attacks"].to_i > 0 }
  end

  def our_top_performers(limit = 10)
    our_members.sort_by { |m| -m["score"].to_f }.first(limit)
  end

  def their_top_performers(limit = 10)
    their_members.sort_by { |m| -m["score"].to_f }.first(limit)
  end

  def our_non_participants
    our_members.select { |m| m["attacks"].to_i == 0 }
  end

  def calculate_reward_value!(api_key)
    items = our_rewards&.dig("items") || []
    return unless items.any?

    item_ids = items.map { |i| i["id"] }.uniq
    prices = fetch_market_prices(api_key, item_ids)

    items.each { |item| item["market_price"] = prices[item["id"]] || 0 }
    total = items.sum { |item| item["market_price"] * item["quantity"] }

    update!(our_rewards: our_rewards.merge("items" => items), reward_estimated_value: total)
  end

  def score_per_attack
    return 0 if our_attacks.to_i.zero?
    (our_score.to_f / our_attacks).round(2)
  end

  def their_score_per_attack
    return 0 if their_attacks.to_i.zero?
    (their_score.to_f / their_attacks).round(2)
  end

  private

  def fetch_market_prices(api_key, item_ids)
    item_ids.each_with_object({}) do |id, prices|
      response = TornApi::Base.new(api_key).send(:get, "v2/market/#{id}/itemmarket", { limit: 1 })
      avg_price = response.dig("itemmarket", "item", "average_price")
      prices[id] = avg_price || 0
    rescue TornApi::ApiError
      prices[id] = 0
    end
  end
end
