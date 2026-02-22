module Daily
  # Orchestrator job that schedules individual sync jobs per faction
  # Runs on default queue, schedules API jobs to owner_api queue
  class FactionMembershipSyncJob < ApplicationJob
    queue_as :default

    def perform
      Faction.tracked.find_each do |faction|
        SyncFactionMembersJob.perform_later(faction.id)
      end
    end
  end
end
