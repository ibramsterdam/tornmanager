class Factions::RankedWarsController < ApplicationController
  include FactionAccess

  before_action :require_faction_member
  before_action :find_war

  def show
    @our_members = @war.our_members.sort_by { |m| -m["score"].to_f }
    @their_members = @war.their_members.sort_by { |m| -m["score"].to_f }
    @our_non_participants = @war.our_non_participants
  end

  private

  def find_war
    @war = @faction.ranked_wars.find_by!(torn_war_id: params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "War not found."
  end
end
