module Elimination
  class Notifier
    AGENCY = "Conspiracy Intelligence Agency".freeze
    RED = 0xED4245
    GREEN = 0x57F287
    ORANGE = 0xFAA61A
    YELLOW = 0xFEE75C
    GREY = 0x4E5058
    BLURPLE = 0x5865F2

    def initialize(setting)
      @setting = setting
    end

    def push_started(push)
      alerts.post(content: "we are getting pushed!", embed: push_embed(push))
    end

    def push_updated(message_id, push)
      alerts.edit(message_id, embed: push_embed(push))
    end

    def push_resolved(message_id, push)
      alerts.edit(message_id, content: "we weathered the push ✅", embed: push_resolved_embed(push))
    end

    def escape_report(data)
      alerts.post(embed: escape_embed(data))
    end

    def escape_embed(data)
      fields = [
        { name: "Current last", value: "#{data[:last_name]} (#{fmt(data[:last_tickets])})", inline: true },
        { name: "Next tick", value: tct(data[:next_tick_at]), inline: true }
      ]
      if data[:cushion]
        fields << { name: "Our cushion", value: signed(data[:cushion]), inline: true }
      end

      {
        title: "🪜 #{data[:team_name]} is climbing out — #{fmt(data[:tickets])} tickets",
        description: "They sat at **#{data[:floor]} or fewer** tickets and just passed **#{data[:threshold]}** in ~#{data[:minutes]} min. The bottom of the table is moving.",
        color: ORANGE,
        fields: fields,
        footer: footer,
        timestamp: Time.current.iso8601
      }
    end

    def tick_report(data)
      if data[:ours]
        alerts.post(content: "we lost a life", embed: tick_embed(data))
      else
        alerts.post(embed: tick_embed(data))
      end
    end

    def team_eliminated(data)
      alerts.post(embed: eliminated_embed(data))
    end

    def standings(teams)
      standings_webhook.post(embed: standings_embed(teams))
    end

    def health_down(failing_since:)
      alerts.post(embed: {
        title: "⚠️ Elimination endpoint not responding",
        description: "No valid response since <t:#{failing_since.to_i}:R>. Alerts are paused so you don't get false pushes. Polling continues and everything resumes automatically.",
        color: YELLOW,
        footer: footer,
        timestamp: Time.current.iso8601
      })
    end

    def health_recovered
      alerts.post(embed: {
        title: "✅ Elimination endpoint back",
        description: "Intel flowing again. Alerts re-armed.",
        color: GREEN,
        footer: footer,
        timestamp: Time.current.iso8601
      })
    end

    def push_embed(push)
      minutes = [ ((push[:next_tick_at] - Time.current) / 60).ceil, 0 ].max
      fields = [
        { name: "Tickets", value: "#{fmt(push[:tickets_before])} → #{fmt(push[:tickets_now])}", inline: true },
        { name: "Pace", value: "−#{push[:pace_per_minute]} / min", inline: true },
        { name: "Next tick", value: "#{tct(push[:next_tick_at])} (#{minutes} min)", inline: true },
        { name: "Cushion above last", value: signed(push[:cushion]), inline: true }
      ]
      if push[:attackers].present?
        value = push[:attackers].map { |name, wins| "#{name} (wins +#{wins})" }.join("\n")
        fields << { name: "Likely attackers", value: value, inline: true }
      end

      {
        title: "🚨 Push on #{push[:team_name]}",
        description: "Lost **#{push[:lost]} tickets in #{push[:window_seconds]} seconds**.",
        color: RED,
        fields: fields,
        footer: footer,
        timestamp: Time.current.iso8601
      }
    end

    def push_resolved_embed(push)
      duration = ((Time.current - push[:started_at]) / 60).round
      {
        title: "✅ Push on #{push[:team_name]} over",
        description: "Drain back to normal after ~#{duration} min.",
        color: GREEN,
        fields: [
          { name: "Tickets", value: "#{fmt(push[:tickets_before])} → #{fmt(push[:tickets_now])} (net −#{fmt(push[:net_loss])})", inline: true },
          { name: "Cushion above last", value: "+#{fmt(push[:cushion])}", inline: true }
        ],
        footer: footer,
        timestamp: Time.current.iso8601
      }
    end

    def tick_embed(data)
      title = if data[:ours]
        "💔 We lost a life — #{data[:loser_lives]} left"
      else
        "🕒 #{data[:loser_name]} lost a life — #{data[:loser_lives]} left"
      end

      bottom = data[:bottom].map { |name, tickets| "#{name} (#{fmt(tickets)})" }.join(" · ")
      description = "**#{tct(data[:tick_at])}** tick, next at **#{tct(data[:tick_at] + 15.minutes)}**.\nLowest tickets: #{bottom}"

      fields = []
      if data[:our_rank]
        position = data[:total_alive] ? "#{data[:our_rank].ordinalize} of #{data[:total_alive]}" : data[:our_rank].ordinalize
        fields << { name: "Our position", value: position, inline: true }
        fields << { name: "Our tickets", value: fmt(data[:our_tickets]), inline: true }
        fields << { name: "Our lives", value: data[:our_lives].to_s, inline: true }
        fields << { name: "Cushion above last", value: signed(data[:cushion]), inline: true }
      end

      {
        title: title,
        description: description,
        color: data[:ours] ? RED : GREY,
        fields: fields,
        footer: footer,
        timestamp: Time.current.iso8601
      }
    end

    def eliminated_embed(data)
      {
        title: "☠️ #{data[:name]} has been eliminated",
        description: "**#{data[:remaining]} teams remain.**",
        color: GREY,
        footer: footer,
        timestamp: Time.current.iso8601
      }
    end

    def standings_embed(teams)
      alive, dead = teams.sort_by { |t| -t.tickets }.partition { |t| !t.eliminated }
      bottom = alive.last
      rows = alive.each_with_index.map do |team, index|
        prefix = if team.name == @setting.team_name
          "+"
        elsif team.torn_id == bottom.torn_id && alive.size > 1
          "-"
        else
          " "
        end
        format("%s%2d  %-21s %7s %6d  %s/%s", prefix, index + 1, team.name.truncate(21), fmt(team.tickets), team.lives, compact(team.wins), compact(team.losses))
      end
      rows += dead.map { |team| format(" --  %-21s eliminated", team.name.truncate(21)) }

      {
        title: standings_title,
        description: "```diff\n  #  team                  tickets  lives   W/L\n#{rows.join("\n")}```",
        color: BLURPLE,
        fields: standings_fields(alive),
        footer: footer,
        timestamp: Time.current.iso8601
      }
    end

    def standings_title
      day = ((Time.current - attacking_start) / 1.day).floor + 1
      day >= 1 ? "📊 Elimination standings — day #{day}" : "📊 Elimination standings"
    end

    def standings_fields(alive)
      ours = alive.find { |team| team.name == @setting.team_name }
      return [] unless ours && alive.size > 1

      lowest_other = alive.reject { |team| team.torn_id == ours.torn_id }.map(&:tickets).min
      fields = [
        { name: "Cushion (last)", value: signed(ours.tickets - lowest_other), inline: true }
      ]

      our_index = alive.index { |team| team.torn_id == ours.torn_id }
      if our_index.positive?
        above = alive[our_index - 1]
        fields << { name: "Gap up (#{our_index.ordinalize})", value: fmt(above.tickets - ours.tickets), inline: true }
      end

      fields << { name: "Next tick", value: tct(Time.at(((Time.current.to_i / 900) + 1) * 900)), inline: true }

      fields
    end

    def attacking_start
      Time.utc(2026, 9, 10, 12)
    end

    private

    def alerts
      @alerts ||= Discord::BotChannel.new(
        Rails.application.credentials.dig(:cia_bot, :bot_token),
        @setting.alerts_channel_id
      )
    end

    def standings_webhook
      alerts
    end

    def footer
      { text: AGENCY }
    end

    def tct(time)
      time.utc.strftime("%H:%M TCT")
    end

    def fmt(number)
      ActiveSupport::NumberHelper.number_to_delimited(number)
    end

    def signed(number)
      number >= 0 ? "+#{fmt(number)}" : "−#{fmt(number.abs)}"
    end

    def compact(number)
      number >= 1000 ? "#{(number / 100).to_f / 10}k" : number.to_s
    end
  end
end
