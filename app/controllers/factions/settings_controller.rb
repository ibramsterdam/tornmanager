class Factions::SettingsController < ApplicationController
  include FactionAccess

  IMPORT_COOLDOWN = 1.minute

  before_action :require_faction_leader, except: [ :share_subscription ]
  before_action :require_faction_whitelisted, only: [ :share_subscription ]

  def show
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting
    @torn_api_key_masked = mask_key(@faction_setting.torn_api_key)
    @tornstats_api_key_masked = mask_key(@faction_setting.tornstats_api_key)
    @spy_report_count = @faction.spy_reports.count
    @last_import_at = Rails.cache.read(import_cache_key)
    @can_import = @last_import_at.nil?
    @seconds_until_import = seconds_until_import
    @whitelisted_users = @faction.whitelisted_users.order(:name)
    @faction_members = @faction.users.active.where.not(id: @whitelisted_users.select(:id)).order(:name)

    # Share subscription
    @subscription_weeks_remaining = Current.user.subscription_weeks_remaining
    @faction_member_count = @faction.users.active.count

    # War polling
    @war_polling_active = @faction.war_polling_active?
  end

  def update
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting

    # Only update keys that were actually provided (non-blank)
    permitted = faction_setting_params
    new_torn_key = permitted.delete(:torn_api_key).presence
    new_tornstats_key = permitted.delete(:tornstats_api_key).presence

    changes_made = false

    # Validate and store Torn API key
    if new_torn_key
      begin
        key_info = TornApi::Key::Info.new(new_torn_key).fetch

        # Require Limited Access key
        unless key_info.access.type == "Limited Access"
          return redirect_to faction_settings_path(@faction),
            alert: "Only Limited Access keys are allowed. Please create a Limited Access key in your Torn settings."
        end

        # Verify the key belongs to the current user
        unless Current.user.admin? || key_info.user.id == Current.user.torn_id
          return redirect_to faction_settings_path(@faction), alert: "This API key does not belong to you."
        end

        @faction_setting.torn_api_key = new_torn_key
        @faction_setting.torn_api_access_type = key_info.access.type
        changes_made = true
      rescue TornApi::InvalidKeyError
        return redirect_to faction_settings_path(@faction), alert: "Invalid Torn API key."
      rescue TornApi::ApiError => e
        return redirect_to faction_settings_path(@faction), alert: "Could not validate Torn API key: #{e.message}"
      end
    end

    # Store TornStats API key (no validation endpoint available)
    if new_tornstats_key
      @faction_setting.tornstats_api_key = new_tornstats_key
      changes_made = true
    end

    if !changes_made
      redirect_to faction_settings_path(@faction), notice: "No changes made."
    elsif @faction_setting.save
      redirect_to faction_settings_path(@faction), notice: "API keys saved successfully."
    else
      redirect_to faction_settings_path(@faction), alert: "Failed to save settings."
    end
  end

  def add_whitelist
    user = @faction.users.find_by(id: params[:user_id])

    if user.nil?
      redirect_to faction_settings_path(@faction), alert: "User not found in this faction."
    elsif @faction.faction_whitelists.exists?(user: user)
      redirect_to faction_settings_path(@faction), notice: "#{user.name} already has access."
    else
      @faction.faction_whitelists.create!(user: user)
      redirect_to faction_settings_path(@faction), notice: "#{user.name} has been granted access."
    end
  end

  def remove_whitelist
    whitelist = @faction.faction_whitelists.find_by(user_id: params[:user_id])

    if whitelist
      name = whitelist.user.name
      whitelist.destroy!
      flash.now[:notice] = "#{name}'s access has been removed."
    else
      flash.now[:alert] = "User not found in whitelist."
    end

    load_whitelist_data
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("whitelist", partial: "factions/settings/whitelist"),
          turbo_stream.append("flash-notifications", partial: "layouts/flash", locals: { type: flash.now[:notice] ? "notice" : "alert", message: flash.now[:notice] || flash.now[:alert] })
        ]
      end
      format.html { redirect_to faction_settings_path(@faction) }
    end
  end

  def delete_torn_key
    setting = @faction.faction_setting
    if setting
      setting.update!(torn_api_key: nil, torn_api_access_type: nil)
      redirect_to faction_settings_path(@faction), notice: "Torn API key deleted."
    else
      redirect_to faction_settings_path(@faction), alert: "No API keys configured."
    end
  end

  def delete_tornstats_key
    setting = @faction.faction_setting
    if setting
      setting.update!(tornstats_api_key: nil)
      redirect_to faction_settings_path(@faction), notice: "TornStats API key deleted."
    else
      redirect_to faction_settings_path(@faction), alert: "No API keys configured."
    end
  end

  def share_subscription
    total_weeks = params[:total_weeks].to_i
    members = @faction.users.active
    member_count = members.count

    if total_weeks <= 0
      return redirect_to faction_settings_path(@faction), alert: "Please enter a valid number of weeks to share."
    end

    if member_count == 0
      return redirect_to faction_settings_path(@faction), alert: "No faction members found."
    end

    if total_weeks % member_count != 0
      return redirect_to faction_settings_path(@faction), alert: "#{total_weeks} weeks cannot be split evenly across #{member_count} members. Try a multiple of #{member_count}."
    end

    weeks_per_member = total_weeks / member_count

    if Current.user.subscription_weeks_remaining < total_weeks
      return redirect_to faction_settings_path(@faction), alert: "You only have #{Current.user.subscription_weeks_remaining} weeks remaining. Cannot share #{total_weeks} weeks."
    end

    ActiveRecord::Base.transaction do
      Current.user.deduct_subscription!(total_weeks)

      grant = FactionSubscriptionGrant.create!(
        torn_faction_id: @faction.torn_id,
        faction: @faction,
        faction_name: @faction.name,
        weeks_granted: total_weeks,
        granted_by: Current.user,
        granted_at: Time.current
      )

      members.each do |member|
        SubscriptionGrant.create!(
          faction_subscription_grant: grant,
          user: member
        )
        member.extend_subscription!(weeks_per_member)
      end
    end

    redirect_to faction_settings_path(@faction), notice: "Shared #{total_weeks} weeks across #{member_count} members (#{weeks_per_member} weeks each)."
  rescue => e
    Rails.logger.error("Share subscription failed for user #{Current.user.torn_id}: #{e.class} - #{e.message}")
    redirect_to faction_settings_path(@faction), alert: "Failed to share subscription: #{e.message}"
  end

  def import_spies
    target_faction_id = params[:target_faction_id].to_s.strip

    if target_faction_id.blank?
      return redirect_to faction_settings_path(@faction), alert: "Please enter a faction ID to import spy data for."
    end

    @faction_setting = @faction.faction_setting
    unless @faction_setting&.tornstats_api_key?
      return redirect_to faction_settings_path(@faction), alert: "TornStats API key must be configured before importing spy data."
    end

    if rate_limited?
      return redirect_to faction_settings_path(@faction), alert: "Import was run recently. Try again in #{seconds_until_import} seconds."
    end

    Rails.cache.write(import_cache_key, Time.current, expires_in: IMPORT_COOLDOWN)

    begin
      spies = TornStatsApi::SpyFaction.new(
        @faction_setting.tornstats_api_key,
        faction_id: target_faction_id
      ).fetch

      imported = 0
      spies.each do |spy|
        import_spy_report(spy)
        imported += 1
      end

      # Invalidate war cache so next poll picks up fresh spy data
      Rails.cache.delete(@faction.war_cache_key)

      redirect_to faction_settings_path(@faction), notice: "Successfully imported #{imported} spy reports."
    rescue TornStatsApi::NotFoundError => e
      redirect_to faction_settings_path(@faction), alert: "No spy data found: #{e.message}"
    rescue TornStatsApi::InvalidKeyError => e
      redirect_to faction_settings_path(@faction), alert: "Invalid TornStats API key: #{e.message}"
    rescue TornStatsApi::ApiError => e
      Rails.logger.error("TornStats import failed: #{e.class} - #{e.message}")
      redirect_to faction_settings_path(@faction), alert: "Import failed: #{e.message}"
    end
  end

  private

  def faction_setting_params
    params.require(:faction_setting).permit(:torn_api_key, :tornstats_api_key)
  end

  def import_cache_key
    "faction:#{@faction.id}:spy_import:last_run"
  end

  def rate_limited?
    Rails.cache.exist?(import_cache_key)
  end

  def seconds_until_import
    last_run = Rails.cache.read(import_cache_key)
    return 0 unless last_run

    remaining = IMPORT_COOLDOWN - (Time.current - last_run)
    [ remaining.to_i, 0 ].max
  end

  def load_whitelist_data
    @whitelisted_users = @faction.whitelisted_users.order(:name)
    @faction_members = @faction.users.active.where.not(id: @whitelisted_users.select(:id)).order(:name)
  end

  def import_spy_report(spy)
    report = @faction.spy_reports.find_or_initialize_by(torn_id: spy.torn_id)
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

  def mask_key(key)
    return nil if key.blank?
    "#{key[0..3]}********#{key[-4..]}"
  end
end
