module Daily
  class FactionMembershipSyncJob < ApplicationJob
    queue_as :default

    def perform
      Faction.find_each do |faction|
        SyncFactionMembersJob.perform_later(faction.id)
      end
    end
  end
end
