module TornApi
  module Faction
    class Attacks < Base
      Attack = Data.define(
        :id, :code, :started, :ended,
        :attacker_id, :attacker_name, :attacker_level, :attacker_faction_id, :attacker_faction_name,
        :defender_id, :defender_name, :defender_level, :defender_faction_id, :defender_faction_name,
        :result, :respect_gain, :respect_loss, :chain,
        :is_ranked_war, :is_stealthed, :is_interrupted, :is_raid,
        :fair_fight, :war, :retaliation, :group, :overseas, :chain_modifier, :warlord,
        :finishing_hit_effects
      )

      Result = Data.define(:attacks, :prev_url)

      def initialize(api_key, from: nil, to: nil, filters: nil, limit: 100)
        super(api_key)
        @from = from
        @to = to
        @filters = filters
        @limit = limit
      end

      MAX_PAGES = 50

      def fetch
        response = get("v2/faction/attacks", build_params)

        attacks = (response["attacks"] || []).map { |a| parse_attack(a) }
        prev_url = response.dig("_metadata", "links", "prev")

        Result.new(attacks: attacks, prev_url: prev_url)
      end

      def fetch_all(max_pages: MAX_PAGES)
        all_attacks = []
        current_to = @to
        pages = 0

        loop do
          break if pages >= max_pages

          params = build_params(to_override: current_to)
          response = get("v2/faction/attacks", params)

          attacks = (response["attacks"] || []).map { |a| parse_attack(a) }
          all_attacks.concat(attacks)
          pages += 1

          prev_url = response.dig("_metadata", "links", "prev")
          break unless prev_url

          current_to = extract_to_param(prev_url)
          break unless current_to
        end

        all_attacks
      end

      private

      def build_params(to_override: nil)
        params = { limit: @limit, sort: "DESC" }
        params[:from] = @from if @from
        to_val = to_override || @to
        params[:to] = to_val if to_val
        params[:filters] = @filters if @filters
        params
      end

      def extract_to_param(url)
        uri = URI.parse(url)
        params = URI.decode_www_form(uri.query || "").to_h
        params["to"]&.to_i
      end

      def parse_attack(data)
        modifiers = data["modifiers"] || {}

        Attack.new(
          id: data["id"],
          code: data["code"],
          started: data["started"],
          ended: data["ended"],
          attacker_id: data.dig("attacker", "id"),
          attacker_name: data.dig("attacker", "name"),
          attacker_level: data.dig("attacker", "level"),
          attacker_faction_id: data.dig("attacker", "faction", "id"),
          attacker_faction_name: data.dig("attacker", "faction", "name"),
          defender_id: data.dig("defender", "id"),
          defender_name: data.dig("defender", "name"),
          defender_level: data.dig("defender", "level"),
          defender_faction_id: data.dig("defender", "faction", "id"),
          defender_faction_name: data.dig("defender", "faction", "name"),
          result: data["result"],
          respect_gain: data["respect_gain"],
          respect_loss: data["respect_loss"],
          chain: data["chain"],
          is_ranked_war: data["is_ranked_war"],
          is_stealthed: data["is_stealthed"],
          is_interrupted: data["is_interrupted"],
          is_raid: data["is_raid"],
          fair_fight: modifiers["fair_fight"],
          war: modifiers["war"],
          retaliation: modifiers["retaliation"],
          group: modifiers["group"],
          overseas: modifiers["overseas"],
          chain_modifier: modifiers["chain"],
          warlord: modifiers["warlord"],
          finishing_hit_effects: data["finishing_hit_effects"] || []
        )
      end
    end
  end
end
