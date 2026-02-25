class Factions::PublicWarController < ApplicationController
  include FactionAccess
  include FactionHelper

  allow_unauthenticated_access only: [ :show ]
  before_action :find_public_faction

  def show
    @current_war = @faction.current_war

    unless @current_war
      redirect_to root_path, alert: "No active war to display."
      return
    end

    @war_data = Rails.cache.read(@faction.war_cache_key)
  end

  private

  def find_public_faction
    torn_id = params[:faction_torn_id] || params[:torn_id]
    @faction = Faction.find_by(torn_id: torn_id)

    unless @faction
      redirect_to root_path, alert: "Faction not found."
      return
    end

    unless @faction.public_wars
      redirect_to root_path, alert: "This faction does not have public wars enabled."
    end
  end
end
