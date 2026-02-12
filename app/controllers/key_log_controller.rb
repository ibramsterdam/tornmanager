class KeyLogController < ApplicationController
  allow_unauthenticated_access

  def index
    # Just render the form - no data yet
  end

  def show
    api_key = params[:api_key]&.squish

    if api_key.blank?
      flash.now[:alert] = "Please provide an API key"
      render :index
      return
    end

    begin
      # First validate the key exists and is valid
      key_info = TornApi::Key::Info.new(api_key)
      key_info.fetch

      # If key is valid, fetch the log
      log_fetcher = TornApi::Key::Log.new(api_key)
      @log_data = log_fetcher.fetch
      @api_key = api_key
    rescue TornApi::InvalidKeyError
      flash.now[:alert] = "Invalid API key provided. Please check your key and try again."
      render :index
    rescue => e
      flash.now[:alert] = "Error fetching key log: #{e.message}"
      render :index
    end
  end
end
