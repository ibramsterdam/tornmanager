class FactionMembersJob < ApplicationJob
  queue_as :default

  def perform(batch_ids)
    api_key = Rails.application.credentials.dig(:bram, :api_key)

    # 50 api calls and generating max 5000 members
    all_members = batch_ids.flat_map do |faction_id|
      TornApi::Faction::Members.new(api_key, faction_id).fetch
    end

    all_members.each do |member|
      TornUser.find_or_create_by(torn_id: member.id) do |user|
        user.name = member.name
        user.level = member.level
      end
    end
  end
end
