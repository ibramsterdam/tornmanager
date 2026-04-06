module TornApi
  module Faction
    class ArmoryNews < Base
      V1_ENDPOINT = "faction"

      def fetch(from: nil, to: nil, limit: 100, sort: nil)
        params = { selections: "armorynews", limit: [ limit, 100 ].min }
        params[:from] = from.to_i if from
        params[:to] = to.to_i if to
        params[:sort] = sort if sort
        response = get(V1_ENDPOINT, params)
        parse(response["armorynews"])
      end

      def fetch_all(since: 1.year.ago, max_entries: 2000)
        all_entries = []
        cursor_to = nil
        floor = since.to_i

        loop do
          params = { selections: "armorynews", limit: 100, sort: "DESC" }
          params[:to] = cursor_to if cursor_to
          params[:from] = floor

          response = get(V1_ENDPOINT, params)
          batch = parse(response["armorynews"])
          break if batch.empty?

          all_entries.concat(batch)
          break if all_entries.size >= max_entries
          break if batch.size < 100

          cursor_to = batch.map { |e| e[:timestamp] }.min - 1
          break if cursor_to < floor
        end

        all_entries.first(max_entries)
      end

      private

      def parse(entries)
        return [] unless entries

        list = if entries.is_a?(Hash)
          entries.map { |id, entry| build_entry(id, entry) }
        elsif entries.is_a?(Array)
          entries.map { |entry| build_entry(entry["id"], entry) }
        else
          []
        end

        list.compact
      end

      def build_entry(id, entry)
        return nil unless entry && entry["news"] && entry["timestamp"]

        text = entry["news"]
        player_name = text[/>([^<]+)<\/a>/, 1]
        player_id = text[/XID=(\d+)/, 1]&.to_i

        plain = text.gsub(/<[^>]+>/, "").strip
        action, item = parse_action(plain, player_name)

        {
          id: id,
          text: ActionController::Base.helpers.sanitize(text, tags: %w[a], attributes: %w[href]),
          timestamp: entry["timestamp"],
          player_name: player_name,
          player_id: player_id,
          action: action,
          item: item
        }
      end

      def parse_action(plain, player_name)
        after_name = plain.sub(/\A#{Regexp.escape(player_name.to_s)}\s*/, "")

        case after_name
        when /\Aloaned (\d+)x (.+?) to/
          [ :loaned, $2 ]
        when /\Areturned (\d+)x (.+)/
          [ :returned, $2 ]
        when /\Adeposited (\d+)x (.+)/
          [ :deposited, $2 ]
        when /\Aused one of the faction's (.+?) items/
          [ :used, $1 ]
        when /\Afilled .+ to create a (.+)/
          [ :filled, $1 ]
        else
          [ :unknown, after_name ]
        end
      end
    end
  end
end
