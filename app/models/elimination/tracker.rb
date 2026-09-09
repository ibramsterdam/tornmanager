module Elimination
  class Tracker
    STATE_CACHE_KEY = "elimination:state".freeze
    TICK_INTERVAL = 15.minutes
    PUSH_EDIT_EVERY = 10.seconds
    COUNTDOWN_EDIT_EVERY = 30.seconds

    def initialize(setting, notifier: Notifier.new(setting))
      @setting = setting
      @notifier = notifier
    end

    def process(teams, at: Time.current)
      @state = load_state
      @teams = teams
      @alive = teams.reject(&:eliminated).sort_by { |team| [ -team.tickets, team.torn_id ] }
      @ours = teams.find { |team| team.name == @setting.team_name }
      @at = at

      record_sample
      detect_pushes
      report_life_ticks
      report_eliminations
      handle_countdown
      post_standings

      @state[:prev_teams] = @teams.to_h { |team| [ team.torn_id, { lives: team.lives, eliminated: team.eliminated } ] }
      save_state
    end

    def self.reset!
      Rails.cache.delete(STATE_CACHE_KEY)
    end

    private

    def record_sample
      samples << {
        at: @at.to_i,
        tickets: @teams.to_h { |team| [ team.torn_id, team.tickets ] },
        wins: @teams.to_h { |team| [ team.torn_id, team.wins ] }
      }
      samples.reject! { |sample| sample[:at] < @at.to_i - @setting.push_window_seconds - 20 }
    end

    def detect_pushes
      baseline = window_baseline
      @alive.each do |team|
        push = pushes[team.torn_id]
        lost = baseline ? baseline[:tickets].fetch(team.torn_id, team.tickets) - team.tickets : 0
        over = lost >= @setting.push_ticket_threshold

        if push
          continue_push(team, push, lost, baseline, over)
        elsif over
          start_push(team, lost, baseline)
        end
      end
    end

    def start_push(team, lost, baseline)
      report = push_report(team, lost, baseline, start_tickets: baseline[:tickets][team.torn_id])
      message_id = @notifier.push_started(report)
      pushes[team.torn_id] = {
        message_id: message_id,
        started_at: @at.to_i,
        start_tickets: baseline[:tickets][team.torn_id],
        last_over_at: @at.to_i,
        last_edit_at: @at.to_i,
        ours: report[:ours]
      }
    end

    def continue_push(team, push, lost, baseline, over)
      push[:last_over_at] = @at.to_i if over

      if @at.to_i - push[:last_over_at] >= @setting.push_resolve_seconds
        @notifier.push_resolved(push[:message_id], resolved_report(team, push))
        pushes.delete(team.torn_id)
      elsif @at.to_i - push[:last_edit_at] >= PUSH_EDIT_EVERY
        @notifier.push_updated(push[:message_id], push_report(team, lost, baseline, start_tickets: push[:start_tickets]))
        push[:last_edit_at] = @at.to_i
      end
    end

    def push_report(team, lost, baseline, start_tickets:)
      window = @setting.push_window_seconds
      {
        ours: team.torn_id == @ours&.torn_id,
        team_name: team.name,
        lost: lost,
        window_seconds: window,
        tickets_before: start_tickets,
        tickets_now: team.tickets,
        pace_per_minute: (lost * 60.0 / window).round,
        cushion: cushion_for(team),
        next_tick_at: next_tick_at,
        attackers: likely_attackers(team, baseline)
      }
    end

    def resolved_report(team, push)
      {
        ours: push[:ours],
        team_name: team.name,
        started_at: Time.at(push[:started_at]),
        tickets_before: push[:start_tickets],
        tickets_now: team.tickets,
        net_loss: push[:start_tickets] - team.tickets,
        cushion: cushion_for(team)
      }
    end

    def likely_attackers(victim, baseline)
      return [] unless baseline

      @alive.filter_map do |team|
        next if team.torn_id == victim.torn_id

        gained = team.wins - baseline[:wins].fetch(team.torn_id, team.wins)
        [ team.name, gained ] if gained.positive?
      end.max_by(2) { |_, gained| gained }
    end

    def report_life_ticks
      @teams.each do |team|
        previous = prev_team(team.torn_id)
        next unless previous && team.lives < previous[:lives]

        @notifier.tick_report(tick_data(team))
        @state[:countdown] = nil if team.torn_id == @ours&.torn_id
      end
    end

    def tick_data(loser)
      bottom = @alive.last(2).reverse
      {
        ours: loser.torn_id == @ours&.torn_id,
        loser_name: loser.name,
        loser_lives: loser.lives,
        tick_at: Time.at((@at.to_i / TICK_INTERVAL.to_i) * TICK_INTERVAL.to_i),
        our_rank: our_rank,
        our_tickets: @ours&.tickets,
        our_lives: @ours&.lives,
        bottom: bottom.map { |team| [ team.name, team.tickets ] },
        cushion: @ours ? cushion_for(@ours) : 0
      }
    end

    def report_eliminations
      @teams.each do |team|
        previous = prev_team(team.torn_id)
        next unless previous && team.eliminated && !previous[:eliminated]

        @notifier.team_eliminated(name: team.name, remaining: @alive.size)
      end
    end

    def handle_countdown
      return unless @setting.life_ticks_active?(@at)
      return unless @ours && !@ours.eliminated && @alive.size > 1
      return if our_rank == 1
      return unless our_rank > @alive.size - @setting.countdown_bottom_ranks

      countdown = @state[:countdown]
      tick_at = next_tick_at

      if countdown.nil? || countdown[:tick_at] != tick_at.to_i
        message_id = @notifier.countdown_started(countdown_data(tick_at))
        @state[:countdown] = { tick_at: tick_at.to_i, message_id: message_id, last_edit_at: @at.to_i }
      elsif @at.to_i - countdown[:last_edit_at] >= COUNTDOWN_EDIT_EVERY
        @notifier.countdown_updated(countdown[:message_id], countdown_data(tick_at))
        countdown[:last_edit_at] = @at.to_i
      end
    end

    def countdown_data(tick_at)
      above = @alive[our_rank - 2]
      {
        rank: our_rank,
        total_alive: @alive.size,
        gap: above.tickets - @ours.tickets,
        escape_team: above.name,
        escape_tickets: above.tickets,
        our_tickets: @ours.tickets,
        tick_at: tick_at
      }
    end

    def post_standings
      interval = @setting.standings_interval_minutes * 60
      return if @state[:last_standings_at] && @at.to_i - @state[:last_standings_at] < interval

      @notifier.standings(@teams)
      @state[:last_standings_at] = @at.to_i
    end

    def our_rank
      return nil unless @ours

      index = @alive.index { |team| team.torn_id == @ours.torn_id }
      index && index + 1
    end

    def cushion_for(team)
      others = @alive.reject { |candidate| candidate.torn_id == team.torn_id }
      return 0 if others.empty?

      team.tickets - others.map(&:tickets).min
    end

    def next_tick_at
      Time.at(((@at.to_i / TICK_INTERVAL.to_i) + 1) * TICK_INTERVAL.to_i)
    end

    def window_baseline
      cutoff = @at.to_i - @setting.push_window_seconds + 1
      samples.select { |sample| sample[:at] <= cutoff }.max_by { |sample| sample[:at] }
    end

    def samples
      @state[:samples] ||= []
    end

    def pushes
      @state[:pushes] ||= {}
    end

    def prev_team(torn_id)
      @state.dig(:prev_teams, torn_id)
    end

    def load_state
      Rails.cache.read(STATE_CACHE_KEY) || {}
    end

    def save_state
      Rails.cache.write(STATE_CACHE_KEY, @state, expires_in: 1.hour)
    end
  end
end
