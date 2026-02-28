class ScriptVersion < ApplicationRecord
  validates :version, presence: true, uniqueness: true
  validates :released_at, presence: true
  validates :script_content, presence: true

  scope :ordered, -> { order(released_at: :desc, created_at: :desc) }

  def self.latest
    ordered.first
  end
end
