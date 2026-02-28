class PublicWarsController < ApplicationController
  allow_unauthenticated_access

  before_action :find_lobby, only: [ :show, :war_data, :unlock, :destroy ]

  def index
    @lobbies = PublicWarLobby.order(created_at: :desc)
    flash.now[:alert] = "This lobby has been terminated." if params[:terminated].present?
  end

  def create
    api_key = params[:api_key].to_s.strip
    faction_torn_id = params[:faction_torn_id].to_i

    unless params[:accept_terms] == "1"
      flash.now[:alert] = "You must accept the Terms of Service and Privacy Policy."
      return render_index_with_error
    end

    if api_key.blank?
      flash.now[:alert] = "API key is required."
      return render_index_with_error
    end

    if faction_torn_id <= 0
      flash.now[:alert] = "Faction Torn ID is required."
      return render_index_with_error
    end

    if PublicWarLobby.count >= PublicWarLobby::MAX_LOBBIES
      flash.now[:alert] = "Maximum number of public lobbies (#{PublicWarLobby::MAX_LOBBIES}) reached. Try again later."
      return render_index_with_error
    end

    # Validate the API key and look up the creator
    begin
      key_info = TornApi::Key::Info.new(api_key).fetch
      creator = TornApi::User::Profile.new(api_key).fetch
    rescue TornApi::InvalidKeyError
      flash.now[:alert] = "Invalid API key. Please check and try again."
      return render_index_with_error
    rescue TornApi::ApiError => e
      flash.now[:alert] = "Torn API error: #{e.message}"
      return render_index_with_error
    end

    # Enforce Public Only key access level
    unless key_info.access.type == "Public Only"
      flash.now[:alert] = "Only Public Only API keys are accepted. Your key has #{key_info.access.type} access. Please create a Public Only key in your Torn API settings."
      return render_index_with_error
    end

    # Fetch faction info
    begin
      faction_info = TornApi::Faction::Basic.new(api_key, faction_torn_id).fetch
      faction_name = faction_info["name"]
    rescue TornApi::NotFoundError
      flash.now[:alert] = "Faction not found. Please check the Torn ID."
      return render_index_with_error
    rescue TornApi::ApiError => e
      flash.now[:alert] = "Could not fetch faction info: #{e.message}"
      return render_index_with_error
    end

    # Find active ranked war
    begin
      wars = TornApi::Faction::RankedWars.new(api_key, faction_torn_id).fetch(limit: 5)
      active_war = wars.find { |w| w["end"].to_i == 0 }
    rescue TornApi::ApiError => e
      flash.now[:alert] = "Could not fetch ranked wars: #{e.message}"
      return render_index_with_error
    end

    unless active_war
      flash.now[:alert] = "No active ranked war found for this faction."
      return render_index_with_error
    end

    # Find opponent faction name from the war data
    opponent = active_war["factions"]&.find { |f| f["id"] != faction_torn_id }
    opponent_name = opponent&.dig("name") || "Unknown"

    # Check for duplicate lobby
    if PublicWarLobby.exists?(faction_torn_id: faction_torn_id)
      flash.now[:alert] = "A lobby already exists for this faction's war."
      return render_index_with_error
    end

    # Create the lobby
    lobby = PublicWarLobby.new(
      faction_torn_id: faction_torn_id,
      faction_name: faction_name,
      opponent_faction_name: opponent_name,
      created_by_name: creator.name,
      created_by_torn_id: creator.id,
      password: params[:password].presence
    )

    unless lobby.save
      flash.now[:alert] = lobby.errors.full_messages.to_sentence
      return render_index_with_error
    end

    # Cache the API key (no expiry — lives until server restart or manual delete)
    Rails.cache.write(lobby.api_key_cache_key, api_key)

    # Start polling
    PublicWarPollingJob.perform_later(lobby.id)

    redirect_to public_war_path(lobby), notice: "Lobby created! Live polling has started."
  end

  def show
    if @lobby.password_protected? && !lobby_unlocked?(@lobby)
      render :unlock
      return
    end

    @war_data = Rails.cache.read(@lobby.war_cache_key)
  end

  def war_data
    data = Rails.cache.read(@lobby.war_cache_key)

    if data
      render json: data
    else
      render json: {}, status: :no_content
    end
  end

  def unlock
    if @lobby.authenticate(params[:password].to_s)
      session[:unlocked_lobbies] ||= []
      session[:unlocked_lobbies] << @lobby.slug unless session[:unlocked_lobbies].include?(@lobby.slug)
      redirect_to public_war_path(@lobby)
    else
      flash.now[:alert] = "Incorrect password."
      render :unlock, status: :unprocessable_entity
    end
  end

  def destroy
    unless params[:confirmation].to_s.strip.downcase == "terminate"
      flash.now[:alert] = "Confirmation text did not match. Please type: terminate"
      @war_data = Rails.cache.read(@lobby.war_cache_key)
      return render :show, status: :unprocessable_entity
    end

    @lobby.terminate!
    redirect_to public_wars_path, notice: "Lobby has been terminated."
  end

  private

  def find_lobby
    @lobby = PublicWarLobby.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { terminated: true }, status: :gone }
      format.html { redirect_to public_wars_path, alert: "This lobby has been terminated." }
    end
  end

  def lobby_unlocked?(lobby)
    return true unless lobby.password_protected?

    session[:unlocked_lobbies]&.include?(lobby.slug)
  end
  helper_method :lobby_unlocked?

  def render_index_with_error
    @lobbies = PublicWarLobby.order(created_at: :desc)
    render :index, status: :unprocessable_entity
  end
end
