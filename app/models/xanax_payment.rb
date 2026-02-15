class XanaxPayment < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :sender, class_name: "User"

  validates :log_id, presence: true, uniqueness: true
  validates :xanax_amount, presence: true, numericality: { greater_than: 0 }
  validates :weeks_granted, presence: true, numericality: { greater_than: 0 }
  validates :processed_at, presence: true

  scope :recent, -> { order(processed_at: :desc) }
end
