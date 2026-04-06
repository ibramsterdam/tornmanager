module TornApi
  module Faction
    class Armory < Base
      SELECTIONS = "weapons,armor"

      ARMOR_SLOT_MAP = {
        "Helmet" => :head,
        "Body" => :chest,
        "Vest" => :chest,
        "Armor" => :chest,
        "Gloves" => :chest,  # fallback, overridden below
        "Pants" => :pants,
        "Boots" => :boots
      }.freeze

      def initialize(api_key, faction_torn_id = nil)
        super(api_key)
        @faction_torn_id = faction_torn_id
      end

      def endpoint
        base = "v2/faction"
        base = "#{base}/#{@faction_torn_id}" if @faction_torn_id
        base
      end

      def fetch
        get(endpoint, { selections: SELECTIONS, striptags: false })
      end

      def fetch_by_member
        response = fetch
        members = Hash.new { |h, k| h[k] = empty_slots }

        parse_items(response["armor"] || [], members, :armor)
        parse_items(response["weapons"] || [], members, :weapon)

        members
      end

      private

      def empty_slots
        { head: [], chest: [], gloves: [], pants: [], boots: [], primary: [], secondary: [], melee: [] }
      end

      def parse_items(items, members, category)
        items.each do |item|
          next unless (item["loaned"] || 0) > 0

          loaned_to = parse_loaned_to(item["loaned_to"])
          name = item["name"]
          slot = category == :armor ? armor_slot(name) : weapon_slot(item["type"])

          loaned_to.each do |member_id|
            members[member_id][slot] << name
          end
        end
      end

      def parse_loaned_to(value)
        case value
        when Integer then [ value ]
        when String then value.split(",").map { |id| id.strip.to_i }
        when Array then value.map(&:to_i)
        else []
        end
      end

      def armor_slot(name)
        return :head if name.match?(/helmet|gas mask/i)
        return :gloves if name.match?(/gloves/i)
        return :boots if name.match?(/boots/i)
        return :pants if name.match?(/pants/i)
        :chest
      end

      def weapon_slot(type)
        case type
        when "Primary" then :primary
        when "Secondary" then :secondary
        when "Melee" then :melee
        else :primary
        end
      end
    end
  end
end
