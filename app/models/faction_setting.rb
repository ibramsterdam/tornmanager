class FactionSetting < ApplicationRecord
  belongs_to :faction

  validates :faction_id, uniqueness: true

  def torn_api_key?
    torn_api_key.present?
  end

  def tornstats_api_key?
    tornstats_api_key.present?
  end

  def keys_configured?
    torn_api_key? && tornstats_api_key?
  end
end
