class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  belongs_to :user, optional: true
end
