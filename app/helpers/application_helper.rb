module ApplicationHelper
  def navbar_faction
    @_navbar_faction ||= begin
      torn_id = params[:faction_torn_id] || params[:torn_id]
      if torn_id.present?
        Faction.find_by(torn_id: torn_id)
      end
    end || Current.user&.faction
  end

  def viewing_other_faction?
    navbar_faction.present? &&
      Current.user&.faction.present? &&
      navbar_faction != Current.user.faction
  end
end
