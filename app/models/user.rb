class User < ApplicationRecord
  has_many :sessions, dependent: :destroy

  def self.upsert_from_torn_profile!(profile, api_key)
    user = find_or_initialize_by(torn_id: profile["id"])
    user.assign_attributes(
      name:     profile["name"],
      level:    profile["level"],
      gender:   profile["gender"],
      api_key: ,
    )
    user.save!
    user
  end
end
