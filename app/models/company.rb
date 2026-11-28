class Company < ApplicationRecord
  has_many :employees, class_name: "User", foreign_key: :company_id, primary_key: :torn_id
  belongs_to :director, class_name: "User", foreign_key: :director_torn_id, primary_key: :torn_id, optional: true

  validates :torn_id, presence: true, uniqueness: true
  validates :company_type_id, presence: true
end
