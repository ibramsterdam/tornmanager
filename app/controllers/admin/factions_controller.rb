module Admin
  class FactionsController < ApplicationController
    before_action :require_admin
    before_action :set_faction, only: [ :edit, :update, :destroy, :toggle_tracking, :sync_members, :backfill_stats, :backfill_user_stats ]

    def index
      @factions = Faction.includes(:users).order(:name)
    end

    def new
      @faction = Faction.new
    end

    def create
      torn_id = params[:torn_id].to_i

      if torn_id <= 0
        @error = "Please enter a valid faction ID."
        return render :new, status: :unprocessable_entity
      end

      if Faction.exists?(torn_id: torn_id)
        @error = "Faction #{torn_id} already exists."
        return render :new, status: :unprocessable_entity
      end

      begin
        api_key = OwnerCredentials.api_key
        faction_info = TornApi::Faction::Basic.new(api_key, torn_id).fetch

        @faction = Faction.new(
          torn_id: torn_id,
          name: faction_info["name"]
        )

        if @faction.save
          SyncFactionMembersJob.perform_now(@faction.id)
          @faction.reload

          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to admin_factions_path, notice: "Faction '#{@faction.name}' added with #{@faction.users.active.count} members." }
          end
        else
          @error = "Failed to save faction: #{@faction.errors.full_messages.join(', ')}"
          render :new, status: :unprocessable_entity
        end
      rescue TornApi::ApiError => e
        @error = "Failed to fetch faction info: #{e.message}"
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      name = @faction.name
      @faction.destroy
      redirect_to admin_factions_path, notice: "Faction '#{name}' removed."
    end

    def edit
    end

    def update
      if @faction.update(faction_params)
        redirect_to admin_factions_path, notice: "Faction targets updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_tracking
      @faction.update!(track_stats: !@faction.track_stats)

      if @faction.track_stats
        SyncFactionMembersJob.perform_now(@faction.id)
        @faction.reload
      end

      render json: { success: true, track_stats: @faction.track_stats, member_count: @faction.users.active.count }
    rescue StandardError => e
      Rails.logger.error("Toggle tracking failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end

    def sync_members
      SyncFactionMembersJob.perform_now(@faction.id)
      @faction.reload
      redirect_to admin_factions_path, notice: "Synced #{@faction.users.active.count} members for '#{@faction.name}'."
    rescue => e
      redirect_to admin_factions_path, alert: "Failed to sync members: #{e.message}"
    end

    def backfill_stats
      start_date = params[:start_date].presence || "2026-01-01"
      end_date = params[:end_date].presence || "2026-01-20"

      begin
        start_date = Date.parse(start_date)
        end_date = Date.parse(end_date)
      rescue ArgumentError
        redirect_to admin_factions_path, alert: "Invalid date format. Please use YYYY-MM-DD."
        return
      end

      if start_date > end_date
        redirect_to admin_factions_path, alert: "Start date must be before end date."
        return
      end

      if end_date > Date.today
        redirect_to admin_factions_path, alert: "End date cannot be in the future."
        return
      end

      user_count = @faction.users.active.count
      date_count = (end_date - start_date).to_i + 1

      if user_count == 0
        redirect_to admin_factions_path, alert: "Faction has no members. Please sync members first."
        return
      end

      BackfillPersonalStatsJob.perform_later(@faction.id, start_date.to_s, end_date.to_s)

      max_api_calls = user_count * date_count * 2
      estimated_minutes = (max_api_calls / 60.0).ceil

      redirect_to admin_factions_path,
                  notice: "Backfill queued for '#{@faction.name}': #{user_count} users × #{date_count} days (up to #{max_api_calls} API calls, ~#{estimated_minutes} minutes)"
    rescue => e
      redirect_to admin_factions_path, alert: "Failed to queue backfill: #{e.message}"
    end

    def backfill_user_stats
      user_id = params[:user_id].to_i
      user = @faction.users.find_by(id: user_id)

      unless user
        redirect_to admin_factions_path, alert: "User not found in this faction."
        return
      end

      start_date = params[:start_date].presence || "2026-01-01"
      end_date = params[:end_date].presence || "2026-01-20"

      begin
        start_date = Date.parse(start_date)
        end_date = Date.parse(end_date)
      rescue ArgumentError
        redirect_to admin_factions_path, alert: "Invalid date format. Please use YYYY-MM-DD."
        return
      end

      if start_date > end_date
        redirect_to admin_factions_path, alert: "Start date must be before end date."
        return
      end

      if end_date > Date.today
        redirect_to admin_factions_path, alert: "End date cannot be in the future."
        return
      end

      date_count = (end_date - start_date).to_i + 1

      BackfillUserStatsJob.perform_later(user.id, start_date.to_s, end_date.to_s)

      max_api_calls = date_count * 2
      estimated_minutes = (max_api_calls / 60.0).ceil

      redirect_to admin_factions_path,
                  notice: "Backfill queued for '#{user.name}': #{date_count} days (up to #{max_api_calls} API calls, ~#{estimated_minutes} minutes)"
    rescue => e
      redirect_to admin_factions_path, alert: "Failed to queue backfill: #{e.message}"
    end

    private

    def set_faction
      @faction = Faction.find_by!(torn_id: params[:id])
    end

    def faction_params
      params.require(:faction).permit(:xanax_target, :energy_refill_target, :nerve_refill_target)
    end
  end
end
