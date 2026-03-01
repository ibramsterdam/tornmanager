class Factions::Leadership::LeadershipAccessController < Factions::Leadership::BaseController
  def create
    user = @faction.users.find_by(id: params[:user_id])

    if user.nil?
      @flash_type = "alert"
      @flash_message = "User not found in this faction."
    elsif user.leadership_access?
      @flash_type = "notice"
      @flash_message = "#{user.name} already has access."
    else
      user.update!(leadership_access: true)
      @flash_type = "notice"
      @flash_message = "#{user.name} has been granted access."
    end

    load_settings_data
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("leadership-access", partial: "factions/leadership/leadership_access"),
          turbo_stream.append("flash-notifications", partial: "layouts/flash", locals: { type: @flash_type, message: @flash_message })
        ]
      end
      format.html { redirect_to faction_leadership_settings_path(@faction), @flash_type.to_sym => @flash_message }
    end
  end

  def destroy
    user = @faction.leadership.find_by(id: params[:user_id])

    if user.nil?
      @flash_type = "alert"
      @flash_message = "User not found in leadership."
    elsif user == Current.user
      @flash_type = "alert"
      @flash_message = "You cannot remove your own access."
    elsif user.faction_leader?
      @flash_type = "alert"
      @flash_message = "#{user.name} is #{user.position} and cannot be removed."
    else
      user.update!(leadership_access: false)
      @flash_type = "notice"
      @flash_message = "#{user.name}'s access has been removed."
    end

    load_settings_data
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("leadership-access", partial: "factions/leadership/leadership_access"),
          turbo_stream.append("flash-notifications", partial: "layouts/flash", locals: { type: @flash_type, message: @flash_message })
        ]
      end
      format.html { redirect_to faction_leadership_settings_path(@faction), @flash_type.to_sym => @flash_message }
    end
  end
end
