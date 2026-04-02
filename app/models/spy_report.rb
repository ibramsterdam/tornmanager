class SpyReport < ApplicationRecord
  belongs_to :faction

  validates :torn_id, presence: true, uniqueness: { scope: :faction_id }

  before_save :recalculate_total

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

  private

  def recalculate_total
    self.total = (strength || 0) + (defense || 0) + (speed || 0) + (dexterity || 0)
  end
end
