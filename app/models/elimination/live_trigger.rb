module Elimination
  class LiveTrigger
    KINDS = %w[standings countdown].freeze

    def initialize(setting, notifier: Notifier.new(setting))
      @setting = setting
      @notifier = notifier
    end

    def send!(kind)
      raise ArgumentError, "Unknown live trigger: #{kind}" unless KINDS.include?(kind)

      teams = TornApi::Torn::Elimination.new(@setting.polling_api_key).fetch
      public_send(kind, teams)
    end

    def standings(teams)
      @notifier.standings(teams)
      :sent
    end

    def countdown(teams)
      alive = teams.reject(&:eliminated).sort_by { |team| [ -team.tickets, team.torn_id ] }
      our_index = alive.index { |team| team.name == @setting.team_name }
      return :no_team unless our_index
      return :first_place if our_index.zero?

      above = alive[our_index - 1]
      ours = alive[our_index]
      @notifier.countdown_started(
        rank: our_index + 1,
        total_alive: alive.size,
        gap: above.tickets - ours.tickets,
        escape_team: above.name,
        escape_tickets: above.tickets,
        our_tickets: ours.tickets,
        tick_at: Time.at(((Time.current.to_i / 900) + 1) * 900)
      )
      :sent
    end
  end
end
