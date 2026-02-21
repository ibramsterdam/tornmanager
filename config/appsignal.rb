Appsignal.configure do |config|
  config.activate_if_environment("production")
  config.name = "TornManager"

  unless Rails.env.test?
    config.push_api_key = Rails.application.credentials.dig(:appsignal, :api_key)
  end
end
