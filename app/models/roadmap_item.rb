class RoadmapItem < ApplicationRecord
  STATUSES = %w[planned in_progress done].freeze
  CATEGORIES = %w[factions stats api admin ui_ux torn_script discord infrastructure].freeze

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  scope :ordered, -> { order(position: :asc, created_at: :desc) }
  scope :by_status, ->(status) { where(status: status).ordered }

  def self.status_label(status)
    {
      "planned" => "Planned",
      "in_progress" => "In Progress",
      "done" => "Done"
    }[status]
  end

  def self.category_label(category)
    {
      "factions" => "Factions",
      "stats" => "Stats",
      "api" => "API",
      "admin" => "Admin",
      "ui_ux" => "UI/UX",
      "torn_script" => "Torn Script",
      "discord" => "Discord",
      "infrastructure" => "Infrastructure"
    }[category]
  end
end
