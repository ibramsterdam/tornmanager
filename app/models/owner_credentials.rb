module OwnerCredentials
  def self.api_key
    Rails.application.credentials.dig(:bram, :full_api_key)
  end
end
