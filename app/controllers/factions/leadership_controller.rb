class Factions::LeadershipController < Factions::Leadership::BaseController
  include FactionHelper

  skip_before_action :require_setup_completed, only: [ :setup, :complete_setup ]
  skip_before_action :require_faction_whitelisted, only: [ :setup, :complete_setup ]
  skip_before_action :require_api_keys_configured, except: [ :show ]
  before_action :require_faction_leader, only: [ :setup, :complete_setup, :update_keys, :delete_torn_key, :delete_tornstats_key, :add_whitelist, :remove_whitelist, :import_spies, :delete_faction_data ]

  def show
    load_wars_data
    load_spy_stats_data
    load_settings_data
    load_data_coverage
    load_api_peak_rate
  end

  def setup
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting
  end

  def complete_setup
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting

    new_torn_key = params.dig(:faction_setting, :torn_api_key).presence
    new_tornstats_key = params.dig(:faction_setting, :tornstats_api_key).presence

    unless new_torn_key.present?
      return redirect_to setup_faction_leadership_path(@faction), alert: "Torn API key is required."
    end

    begin
      key_info = TornApi::Key::Info.new(new_torn_key).fetch

      unless key_info.access.type == "Limited Access"
        return redirect_to setup_faction_leadership_path(@faction),
          alert: "Only Limited Access keys are allowed. Please create a Limited Access key in your Torn settings."
      end

      unless Current.user.admin? || key_info.user.id == Current.user.torn_id
        return redirect_to setup_faction_leadership_path(@faction), alert: "This API key does not belong to you."
      end

      @faction_setting.torn_api_key = new_torn_key
      @faction_setting.torn_api_access_type = key_info.access.type

      if new_tornstats_key.present?
        @faction_setting.tornstats_api_key = new_tornstats_key
      end

      @faction_setting.save!

      redirect_to faction_leadership_path(@faction), notice: "Faction configured successfully! You now have access to war tracking and analytics."
    rescue TornApi::InvalidKeyError
      redirect_to setup_faction_leadership_path(@faction), alert: "Invalid Torn API key."
    rescue TornApi::ApiError => e
      redirect_to setup_faction_leadership_path(@faction), alert: "Could not validate Torn API key: #{e.message}"
    end
  end

  def war_data
    war_data = Rails.cache.read(@faction.war_cache_key)

    if war_data
      render json: war_data
    else
      render json: {}, status: :no_content
    end
  end

  def update_keys
    @faction_setting = @faction.faction_setting || @faction.build_faction_setting

    new_torn_key = params.dig(:faction_setting, :torn_api_key).presence
    new_tornstats_key = params.dig(:faction_setting, :tornstats_api_key).presence

    changes_made = false

    if new_torn_key
      begin
        key_info = TornApi::Key::Info.new(new_torn_key).fetch

        unless key_info.access.type == "Limited Access"
          return redirect_to faction_leadership_settings_path(@faction),
            alert: "Only Limited Access keys are allowed."
        end

        unless Current.user.admin? || key_info.user.id == Current.user.torn_id
          return redirect_to faction_leadership_settings_path(@faction), alert: "This API key does not belong to you."
        end

        @faction_setting.torn_api_key = new_torn_key
        @faction_setting.torn_api_access_type = key_info.access.type
        changes_made = true
      rescue TornApi::InvalidKeyError
        return redirect_to faction_leadership_settings_path(@faction), alert: "Invalid Torn API key."
      rescue TornApi::ApiError => e
        return redirect_to faction_leadership_settings_path(@faction), alert: "Could not validate Torn API key: #{e.message}"
      end
    end

    if new_tornstats_key
      @faction_setting.tornstats_api_key = new_tornstats_key
      changes_made = true
    end

    if !changes_made
      redirect_to faction_leadership_settings_path(@faction), notice: "No changes made."
    elsif @faction_setting.save
      redirect_to faction_leadership_settings_path(@faction), notice: "API keys saved successfully."
    else
      redirect_to faction_leadership_settings_path(@faction), alert: "Failed to save settings."
    end
  end

  def delete_torn_key
    setting = @faction.faction_setting
    if setting
      setting.update!(torn_api_key: nil, torn_api_access_type: nil)
      redirect_to faction_leadership_settings_path(@faction), notice: "Torn API key deleted."
    else
      redirect_to faction_leadership_settings_path(@faction), alert: "No API keys configured."
    end
  end

  def delete_tornstats_key
    setting = @faction.faction_setting
    if setting
      setting.update!(tornstats_api_key: nil)
      redirect_to faction_leadership_settings_path(@faction), notice: "TornStats API key deleted."
    else
      redirect_to faction_leadership_settings_path(@faction), alert: "No API keys configured."
    end
  end

  def add_whitelist
    user = @faction.users.find_by(id: params[:user_id])

    if user.nil?
      @flash_type = "alert"
      @flash_message = "User not found in this faction."
    elsif @faction.faction_whitelists.exists?(user: user)
      @flash_type = "notice"
      @flash_message = "#{user.name} already has access."
    else
      @faction.faction_whitelists.create!(user: user)
      @flash_type = "notice"
      @flash_message = "#{user.name} has been granted access."
    end

    load_settings_data
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("whitelist", partial: "factions/leadership/whitelist"),
          turbo_stream.append("flash-notifications", partial: "layouts/flash", locals: { type: @flash_type, message: @flash_message })
        ]
      end
      format.html { redirect_to faction_leadership_settings_path(@faction), @flash_type.to_sym => @flash_message }
    end
  end

  def remove_whitelist
    whitelist = @faction.faction_whitelists.find_by(user_id: params[:user_id])

    if whitelist
      name = whitelist.user.name
      whitelist.destroy!
      @flash_type = "notice"
      @flash_message = "#{name}'s access has been removed."
    else
      @flash_type = "alert"
      @flash_message = "User not found in whitelist."
    end

    load_settings_data
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("whitelist", partial: "factions/leadership/whitelist"),
          turbo_stream.append("flash-notifications", partial: "layouts/flash", locals: { type: @flash_type, message: @flash_message })
        ]
      end
      format.html { redirect_to faction_leadership_settings_path(@faction), @flash_type.to_sym => @flash_message }
    end
  end

  def share_subscription
    total_weeks = params[:total_weeks].to_i
    members = @faction.users.active
    member_count = members.count

    if total_weeks <= 0
      return redirect_to faction_leadership_settings_path(@faction), alert: "Please enter a valid number of weeks to share."
    end

    if member_count == 0
      return redirect_to faction_leadership_settings_path(@faction), alert: "No faction members found."
    end

    if total_weeks % member_count != 0
      return redirect_to faction_leadership_settings_path(@faction), alert: "#{total_weeks} weeks cannot be split evenly across #{member_count} members. Try a multiple of #{member_count}."
    end

    weeks_per_member = total_weeks / member_count

    if Current.user.subscription_weeks_remaining < total_weeks
      return redirect_to faction_leadership_settings_path(@faction), alert: "You only have #{Current.user.subscription_weeks_remaining} weeks remaining. Cannot share #{total_weeks} weeks."
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

    redirect_to faction_leadership_settings_path(@faction), notice: "Shared #{total_weeks} weeks across #{member_count} members (#{weeks_per_member} weeks each)."
  rescue => e
    Rails.logger.error("Share subscription failed for user #{Current.user.torn_id}: #{e.class} - #{e.message}")
    redirect_to faction_leadership_settings_path(@faction), alert: "Failed to share subscription: #{e.message}"
  end

  def import_spies
    target_faction_id = params[:target_faction_id].to_s.strip

    if target_faction_id.blank?
      return redirect_to faction_leadership_spy_reports_path(@faction), alert: "Please enter a faction ID to import spy data for."
    end

    @faction_setting = @faction.faction_setting
    unless @faction_setting&.tornstats_api_key?
      return redirect_to faction_leadership_spy_reports_path(@faction), alert: "TornStats API key must be configured before importing spy data."
    end

    if rate_limited?
      return redirect_to faction_leadership_spy_reports_path(@faction), alert: "Import was run recently. Try again in #{seconds_until_import} seconds."
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

      Rails.cache.delete(@faction.war_cache_key)

      redirect_to faction_leadership_spy_reports_path(@faction), notice: "Successfully imported #{imported} spy reports."
    rescue TornStatsApi::NotFoundError => e
      redirect_to faction_leadership_spy_reports_path(@faction), alert: "No spy data found: #{e.message}"
    rescue TornStatsApi::InvalidKeyError => e
      redirect_to faction_leadership_spy_reports_path(@faction), alert: "Invalid TornStats API key: #{e.message}"
    rescue TornStatsApi::ApiError => e
      Rails.logger.error("TornStats import failed: #{e.class} - #{e.message}")
      redirect_to faction_leadership_spy_reports_path(@faction), alert: "Import failed: #{e.message}"
    end
  end

  def delete_faction_data
    user_ids = @faction.users.pluck(:id)

    ActiveRecord::Base.transaction do
      @faction.stop_war_polling! if @faction.war_polling_active?
      @faction.clear_backfill_status! if @faction.backfill_in_progress?

      PersonalStatSnapshot.where(user_id: user_ids).delete_all if user_ids.any?
      @faction.spy_reports.delete_all
      @faction.ranked_wars.delete_all
      @faction.faction_whitelists.delete_all
      @faction.faction_setting&.destroy!
      @faction.update!(setup_completed: false)
    end

    cancel_faction_jobs(user_ids)

    redirect_to faction_path(@faction), notice: "All faction data has been deleted. Subscription time has been preserved."
  rescue => e
    Rails.logger.error("Delete faction data failed for faction #{@faction.torn_id}: #{e.class} - #{e.message}")
    redirect_to faction_leadership_settings_path(@faction), alert: "Failed to delete faction data: #{e.message}"
  end

  private

  def cancel_faction_jobs(user_ids)
    faction_id = @faction.id

    SolidQueue::Job
      .where(finished_at: nil)
      .where(class_name: %w[
        BackfillPersonalStatsJob
        BackfillRankedWarsJob
        ClearBackfillStatusJob
        WarPollingJob
      ])
      .where("arguments LIKE ?", "%\"arguments\":[#{faction_id},%")
      .destroy_all

    if user_ids.any?
      SolidQueue::Job
        .where(finished_at: nil)
        .where(class_name: %w[BackfillSingleStatJob BackfillUserStatsJob])
        .where(user_ids.map { |uid| "arguments LIKE '%\"arguments\":[#{uid},%'" }.join(" OR "))
        .destroy_all
    end

    SolidQueue::Semaphore.where(key: "war_polling_faction_#{faction_id}").delete_all
  rescue => e
    Rails.logger.warn("Failed to cancel faction jobs for faction #{@faction.torn_id}: #{e.class} - #{e.message}")
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
end
