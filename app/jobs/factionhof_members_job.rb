class FactionhofMembersJob < ApplicationJob
  queue_as :default

  TOP_FACTIONS_COUNT = 4000

  def perform
    (0...TOP_FACTIONS_COUNT).step(100).each do |offset|
      FetchFactionHofPageJob.perform_later(offset)
    end

    Rails.logger.info "FactionhofMembersJob: Scheduled #{TOP_FACTIONS_COUNT / 100} HOF page fetch jobs"
  end
end
