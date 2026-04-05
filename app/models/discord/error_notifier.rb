module Discord
  class ErrorNotifier
    def report(error, handled:, severity:, context:, source: nil)
      return if handled

      Discord::Notifier.notify(
        webhook_key: :error_webhook_url,
        embed: {
          title: error.class.to_s,
          description: "```#{error.message.truncate(1000)}```",
          color: 15_158_332,
          fields: [
            { name: "Source", value: source || "unknown", inline: true },
            { name: "Severity", value: severity.to_s, inline: true }
          ],
          footer: { text: "TornManager Error Reporter" },
          timestamp: Time.current.iso8601
        }
      )
    end
  end
end
