class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  belongs_to :torn_user, optional: true
end
