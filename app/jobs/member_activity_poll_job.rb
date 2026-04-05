class MemberActivityPollJob < ApplicationJob
  queue_as :default

  def perform
    Faction.where(setup_completed: true).find_each do |faction|
      next unless faction.torn_api_key.present?

      FetchMemberActivityJob.perform_later(faction.id)
    end
  end
end
