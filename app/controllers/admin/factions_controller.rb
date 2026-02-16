module Admin
  class FactionsController < ApplicationController
    before_action :require_admin
    before_action :set_faction, only: [ :destroy, :toggle_tracking, :sync_members ]

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
          name: faction_info["name"],
          track_stats: false
        )

        if @faction.save
          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to admin_factions_path, notice: "Faction '#{@faction.name}' added successfully." }
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

    def toggle_tracking
      @faction.update!(track_stats: !@faction.track_stats)

      if @faction.track_stats
        # Sync members immediately when tracking is enabled
        Daily::FactionMembershipSyncJob.new.sync_faction_members(@faction)
        render json: { success: true, track_stats: @faction.track_stats, member_count: @faction.users.count }
      else
        render json: { success: true, track_stats: @faction.track_stats, member_count: @faction.users.count }
      end
    rescue => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end

    def sync_members
      Daily::FactionMembershipSyncJob.new.sync_faction_members(@faction)
      redirect_to admin_factions_path, notice: "Synced #{@faction.users.count} members for '#{@faction.name}'."
    rescue => e
      redirect_to admin_factions_path, alert: "Failed to sync members: #{e.message}"
    end

    private

    def set_faction
      @faction = Faction.find(params[:id])
    end
  end
end
