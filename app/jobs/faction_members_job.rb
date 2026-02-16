class FactionMembersJob < ApplicationJob
  queue_as :default

  def perform(batch_ids)
    # 50 api calls and generating max 5000 members
    all_members = batch_ids.flat_map do |faction_id|
      TornApi::Faction::Members.new(OwnerCredentials.api_key, faction_id).fetch
    end

    all_members.each do |member|
      User.find_or_create_by(torn_id: member.id) do |user|
        user.name = member.name
        user.level = member.level
        # api_key is nil until they log in
      end
    end
  end
end
