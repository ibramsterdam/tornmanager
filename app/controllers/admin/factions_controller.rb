module Admin
  class FactionsController < ApplicationController
    before_action :require_admin
    before_action :set_faction, only: [ :edit, :update, :destroy, :toggle_ssl, :toggle_public_wars ]

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
        api_key = AdminCredentials.api_key
        faction_info = TornApi::Faction::Basic.new(api_key, torn_id).fetch

        @faction = Faction.new(
          torn_id: torn_id,
          name: faction_info["name"]
        )

        if @faction.save
          SyncFactionMembersJob.perform_now(@faction.id)
          BackfillRankedWarsJob.perform_later(@faction.id, limit: 20)
          @faction.reload

          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to admin_factions_path, notice: "Faction '#{@faction.name}' added with #{@faction.users.active.count} members. War history backfill queued." }
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
      @faction.delete_all_data!
      redirect_to admin_factions_path, notice: "Faction '#{@faction.name}' reset. Setup required to reconfigure."
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

    def toggle_ssl
      user = @faction.users.find_by(id: params[:user_id])

      unless user
        render json: { success: false, error: "User not found" }, status: :not_found
        return
      end

      user.update!(ssl_user: !user.ssl_user)
      render json: { success: true, ssl_user: user.ssl_user, user_name: user.name }
    rescue StandardError => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end

    def toggle_public_wars
      @faction.update!(public_wars: !@faction.public_wars)
      render json: { success: true, public_wars: @faction.public_wars }
    rescue StandardError => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
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
