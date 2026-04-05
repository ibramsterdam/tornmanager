module Discord
  class ErrorNotifier
    APP_TRACE_LIMIT = 8

    def report(error, handled:, severity:, context:, source: nil)
      return if handled

      fields = [
        { name: "Source", value: source || "unknown", inline: true },
        { name: "Severity", value: severity.to_s, inline: true },
        { name: "Environment", value: Rails.env, inline: true }
      ]

      trace = app_backtrace(error)
      if trace.present?
        fields << { name: "Stacktrace", value: "```\n#{trace}\n```", inline: false }
      end

      Discord::Notifier.notify(
        webhook_key: :error_webhook_url,
        embed: {
          title: error.class.to_s,
          description: "```#{error.message.truncate(1000)}```",
          color: 15_158_332,
          fields: fields,
          footer: { text: "TornManager Error Reporter" },
          timestamp: Time.current.iso8601
        }
      )
    end

    private

    def app_backtrace(error)
      return nil unless error.backtrace

      root = Rails.root.to_s
      app_lines = error.backtrace
        .select { |line| line.start_with?(root) }
        .map { |line| line.delete_prefix("#{root}/") }
        .first(APP_TRACE_LIMIT)

      return nil if app_lines.empty?

      app_lines.join("\n").truncate(900)
    end
  end
end
