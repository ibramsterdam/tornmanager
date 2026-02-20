class SpyReport < ApplicationRecord
  belongs_to :faction

  validates :torn_id, presence: true, uniqueness: { scope: :faction_id }

  scope :for_targets, ->(torn_ids) { where(torn_id: torn_ids) }

  def stats_hash
    {
      strength: strength,
      defense: defense,
      speed: speed,
      dexterity: dexterity,
      total: total
    }
  end
end
