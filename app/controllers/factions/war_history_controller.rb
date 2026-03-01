class Factions::WarHistoryController < ApplicationController
  include FactionAccess

  before_action :require_faction_member

  def show
    @wars = @faction.ranked_wars.recent.includes(:faction)

    current_year_wars = @wars.completed.where(started_at: Date.current.beginning_of_year..)
    @wins = current_year_wars.won.count
    @losses = current_year_wars.lost.count

    @member_performance = calculate_member_performance(current_year_wars)
  end

  private

  def calculate_member_performance(wars)
    return [] if wars.empty?

    performance = {}

    wars.each do |war|
      next unless war.our_members.present?

      war.our_members.each do |member|
        torn_id = member["id"].to_s
        name = member["name"]

        performance[torn_id] ||= {
          name: name,
          torn_id: torn_id,
          wars_participated: 0,
          total_attacks: 0,
          total_score: 0.0
        }

        attacks = member["attacks"].to_i
        if attacks > 0
          performance[torn_id][:wars_participated] += 1
          performance[torn_id][:total_attacks] += attacks
          performance[torn_id][:total_score] += member["score"].to_f
        end
      end
    end

    performance.values.map do |p|
      p[:avg_attacks] = p[:wars_participated] > 0 ? (p[:total_attacks].to_f / p[:wars_participated]).round(1) : 0
      p[:avg_score] = p[:wars_participated] > 0 ? (p[:total_score] / p[:wars_participated]).round(1) : 0
      p[:avg_respect_per_hit] = p[:total_attacks] > 0 ? (p[:total_score] / p[:total_attacks]).round(2) : 0
      p
    end.sort_by { |p| -p[:total_score] }
  end
end
