class SubscriptionGrant < ApplicationRecord
  belongs_to :faction_subscription_grant
  belongs_to :user

  validates :user_id, uniqueness: { scope: :faction_subscription_grant_id }
end
