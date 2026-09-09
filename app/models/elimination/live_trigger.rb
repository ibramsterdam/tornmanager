module Elimination
  class LiveTrigger
    KINDS = %w[standings].freeze

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
  end
end
