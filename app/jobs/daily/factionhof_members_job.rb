# Orchestrator job that schedules HOF page fetches
# Runs on default queue, schedules API jobs to owner_api queue
class Daily::FactionhofMembersJob < ApplicationJob
  queue_as :default

  TOP_FACTIONS_COUNT = 4000

  def perform
    # Schedule 40 page fetches (100 factions per page, 4000 total)
    # Each page fetch will then schedule member fetches for each faction
    # The owner_api queue handles rate limiting automatically
    (0...TOP_FACTIONS_COUNT).step(100).each do |offset|
      FetchFactionHofPageJob.perform_later(offset)
    end

    Rails.logger.info "FactionhofMembersJob: Scheduled #{TOP_FACTIONS_COUNT / 100} HOF page fetch jobs"
  end
end
