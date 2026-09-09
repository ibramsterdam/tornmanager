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
      if push[:ours]
        alerts.post(content: ping("we are getting pushed!"), embed: push_embed(push), allowed_mentions: role_mentions)
      else
        alerts.post(embed: push_embed(push))
      end
    end

    def push_updated(message_id, push)
      alerts.edit(message_id, embed: push_embed(push))
    end

    def push_resolved(message_id, push)
      alerts.edit(message_id, embed: push_resolved_embed(push))
    end

    def countdown_started(data)
      alerts.post(content: ping("attack NOW or we lose a life"), embed: countdown_embed(data), allowed_mentions: role_mentions)
    end

    def countdown_updated(message_id, data)
      alerts.edit(message_id, embed: countdown_embed(data))
    end

    def tick_report(data)
      if data[:ours]
        alerts.post(content: ping("we lost a life"), embed: tick_embed(data), allowed_mentions: role_mentions)
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
        { name: "Next tick", value: "#{tct(push[:next_tick_at])} (#{minutes} min)", inline: true }
      ]
      if push[:ours]
        fields << { name: "Cushion above last", value: "+#{fmt(push[:cushion])}", inline: true }
      end
      if push[:attackers].present?
        value = push[:attackers].map { |name, wins| "#{name} (wins +#{wins})" }.join("\n")
        fields << { name: "Likely attackers", value: value, inline: true }
      end

      {
        title: "🚨 Push on #{push[:team_name]}",
        description: "Lost **#{push[:lost]} tickets in #{push[:window_seconds]} seconds**.",
        color: push[:ours] ? RED : ORANGE,
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

    def countdown_embed(data)
      minutes = [ ((data[:tick_at] - Time.current) / 60).ceil, 0 ].max
      position = data[:rank] == data[:total_alive] ? "we are LAST" : "we are #{data[:rank].ordinalize} of #{data[:total_alive]}"
      {
        title: "⏳ #{minutes} min to the #{tct(data[:tick_at])} tick and #{position}",
        description: "We need **+#{fmt(data[:gap] + 1)} tickets** to pass **#{data[:escape_team]}** before the tick. Every won attack counts for one.",
        color: RED,
        fields: [
          { name: "Us", value: fmt(data[:our_tickets]), inline: true },
          { name: data[:escape_team], value: fmt(data[:escape_tickets]), inline: true },
          { name: "Tick", value: tct(data[:tick_at]), inline: true }
        ],
        footer: footer,
        timestamp: Time.current.iso8601
      }
    end

    def tick_embed(data)
      title = if data[:ours]
        "💔 #{tct(data[:tick_at])} tick: we lost a life (#{data[:loser_lives]} left)"
      else
        "🕒 #{tct(data[:tick_at])} tick: #{data[:loser_name]} lost a life (#{data[:loser_lives]} left)"
      end

      {
        title: title,
        color: data[:ours] ? RED : GREY,
        fields: [
          { name: "Us", value: "#{data[:our_rank].ordinalize} · #{fmt(data[:our_tickets])} tickets · #{data[:our_lives]} lives", inline: true },
          { name: "Bottom two", value: data[:bottom].map { |name, tickets| "#{name} #{fmt(tickets)}" }.join("\n"), inline: true },
          { name: "Cushion", value: "+#{fmt(data[:cushion])}", inline: true }
        ],
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
      rows = alive.each_with_index.map do |team, index|
        marker = team.name == @setting.team_name ? "▸" : " "
        format("%s%2d  %-21s %7s %6d  %s/%s", marker, index + 1, team.name.truncate(21), fmt(team.tickets), team.lives, compact(team.wins), compact(team.losses))
      end
      rows += dead.map { |team| format("  --  %-21s eliminated", team.name.truncate(21)) }

      {
        title: "📊 Elimination standings",
        description: "```  #  team                  tickets  lives  W/L\n#{rows.join("\n")}```",
        color: BLURPLE,
        footer: footer,
        timestamp: Time.current.iso8601
      }
    end

    private

    def alerts
      @alerts ||= Discord::Webhook.new(@setting.alerts_webhook_url)
    end

    def standings_webhook
      @standings_webhook ||= Discord::Webhook.new(@setting.standings_webhook_url.presence || @setting.alerts_webhook_url)
    end

    def ping(message)
      return message unless @setting.role_id.present?
      "<@&#{@setting.role_id}> #{message}"
    end

    def role_mentions
      return nil unless @setting.role_id.present?
      { parse: [], roles: [ @setting.role_id ] }
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

    def compact(number)
      number >= 1000 ? "#{(number / 100).to_f / 10}k" : number.to_s
    end
  end
end
