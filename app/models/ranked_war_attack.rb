class RankedWarAttack < ApplicationRecord
  belongs_to :ranked_war

  validates :torn_attack_id, presence: true, uniqueness: { scope: :ranked_war_id }
  validates :attacker_id, presence: true
  validates :defender_id, presence: true
  validates :result, presence: true

  scope :outgoing, ->(faction_torn_id) { where(attacker_faction_id: faction_torn_id) }
  scope :incoming, ->(faction_torn_id) { where(defender_faction_id: faction_torn_id) }

  def used_warlord?
    warlord.present? && warlord > 1
  end

  def overseas?
    self.overseas.present? && self.overseas > 1
  end
end
