module AdminCredentials
  def self.api_key
    Rails.application.credentials.dig(:admin, :api_key)
  end
end
