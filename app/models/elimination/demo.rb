module Elimination
  class Demo
    KINDS = %w[
      push_ours push_rival push_resolved countdown
      tick_other tick_ours elimination standings
      health_down health_recovered
    ].freeze

    Team = TornApi::Torn::Elimination::Team

    def initialize(setting, notifier: Notifier.new(setting))
      @setting = setting
      @notifier = notifier
    end

    def send!(kind)
      raise ArgumentError, "Unknown demo kind: #{kind}" unless KINDS.include?(kind)

      public_send(kind)
    end

    def push_ours
      @notifier.push_started(our_push)
    end

    def push_rival
      @notifier.push_started(
        ours: false, team_name: "Brain Surgeons", lost: 11,
        window_seconds: @setting.push_window_seconds,
        tickets_before: 575, tickets_now: 564, pace_per_minute: 66,
        cushion: 76, next_tick_at: next_tick,
        attackers: [ [ "High Voltage", 9 ] ]
      )
    end

    def push_resolved
      message_id = @notifier.push_started(our_push)
      @notifier.push_resolved(
        message_id,
        ours: true, team_name: @setting.team_name, started_at: 8.minutes.ago,
        tickets_before: 1384, tickets_now: 1298, net_loss: 86, cushion: 810
      )
    end

    def countdown
      @notifier.countdown_started(
        rank: 11, total_alive: 11, gap: 55,
        escape_team: "Inanimate Objects", escape_tickets: 1186,
        our_tickets: 1131, tick_at: next_tick
      )
    end

    def tick_other
      @notifier.tick_report(tick_data.merge(ours: false, loser_name: "Inanimate Objects", loser_lives: 17))
    end

    def tick_ours
      @notifier.tick_report(tick_data.merge(ours: true, loser_name: @setting.team_name, loser_lives: 47, our_lives: 47))
    end

    def elimination
      @notifier.team_eliminated(name: "Gold Dust", remaining: 11)
    end

    def standings
      @notifier.standings(teams)
    end

    def health_down
      @notifier.health_down(failing_since: 4.minutes.ago)
    end

    def health_recovered
      @notifier.health_recovered
    end

    private

    def our_push
      {
        ours: true, team_name: @setting.team_name, lost: 14,
        window_seconds: @setting.push_window_seconds,
        tickets_before: 1384, tickets_now: 1370, pace_per_minute: 84,
        cushion: 806, next_tick_at: next_tick,
        attackers: [ [ "Reptilians", 11 ], [ "APEX", 3 ] ]
      }
    end

    def tick_data
      {
        tick_at: previous_tick,
        our_rank: 3, our_tickets: 1298, our_lives: 48,
        bottom: [ [ "Inanimate Objects", 488 ], [ "Brain Surgeons", 564 ] ],
        cushion: 810
      }
    end

    def teams
      [
        [ 83, "Reptilians", 2412, 50, 9412, 8000 ],
        [ 86, "APEX", 2118, 50, 8644, 7526 ],
        [ 80, @setting.team_name, 1298, 48, 7921, 7537 ],
        [ 89, "High Voltage", 1290, 44, 7410, 7120 ],
        [ 84, "Rocket Scientists", 1105, 41, 6988, 6883 ],
        [ 88, "Nine Lives", 982, 37, 6540, 6558 ],
        [ 85, "Sticks and Stones", 871, 33, 6214, 6343 ],
        [ 87, "Touching Grass", 760, 28, 5830, 6070 ],
        [ 90, "Loose Cannons", 655, 24, 5411, 5756 ],
        [ 70, "Brain Surgeons", 564, 18, 5120, 5632 ],
        [ 81, "Inanimate Objects", 488, 17, 4872, 5561 ],
        [ 82, "Gold Dust", 0, 0, 4100, 6200, true ]
      ].map do |torn_id, name, tickets, lives, wins, losses, eliminated|
        Team.new(torn_id, name, 2027, 0, tickets, lives, wins, losses, eliminated || false, nil)
      end
    end

    def next_tick
      Time.at(((Time.current.to_i / 900) + 1) * 900)
    end

    def previous_tick
      Time.at((Time.current.to_i / 900) * 900)
    end
  end
end
