module TornApi
  module User
    class PersonalStats < Base
      attr_reader :torn_id

      def initialize(api_key, torn_id)
        super(api_key)
        @torn_id = torn_id
      end

      def endpoint
        "v2/user/#{@torn_id}/personalstats"
      end

      def fetch
        response = get(endpoint, cat: "all", striptags: false)
        if response["personalstats"].present?
          parse_personalstats(response["personalstats"])
        else
          raise InvalidKeyError, "Torn API authentication failed: #{response['error']&.dig('description')}"
        end
      end

      PersonalStatSnapshot = Data.define(
        # Attacking
        :attacking_attacks_won,
        :attacking_attacks_lost,
        :attacking_attacks_stalemate,
        :attacking_attacks_assist,
        :attacking_attacks_stealth,
        :attacking_defends_won,
        :attacking_defends_lost,
        :attacking_defends_stalemate,
        :attacking_defends_total,
        :attacking_elo,
        :attacking_unarmored_wins,
        :attacking_highest_level_beaten,
        :attacking_escapes_player,
        :attacking_escapes_foes,
        :attacking_killstreak_best,
        :attacking_hits_success,
        :attacking_hits_miss,
        :attacking_hits_critical,
        :attacking_hits_one_hit_kills,
        :attacking_damage_total,
        :attacking_damage_best,
        :attacking_networth_money_mugged,
        :attacking_networth_largest_mug,
        :attacking_networth_items_looted,
        :attacking_ammunition_total,
        :attacking_ammunition_special,
        :attacking_ammunition_hollow_point,
        :attacking_ammunition_tracer,
        :attacking_ammunition_piercing,
        :attacking_ammunition_incendiary,
        :attacking_faction_respect,
        :attacking_faction_retaliations,
        :attacking_faction_ranked_war_hits,
        :attacking_faction_raid_hits,
        :attacking_faction_territory_wall_joins,
        :attacking_faction_territory_wall_clears,
        :attacking_faction_territory_wall_time,

        # Jobs
        :jobs_job_points_used,
        :jobs_trains_received,

        # Trading
        :trading_items_bought_market,
        :trading_items_bought_shops,
        :trading_items_auctions_won,
        :trading_items_auctions_sold,
        :trading_items_sent,
        :trading_trades,
        :trading_points_bought,
        :trading_points_sold,
        :trading_bazaar_customers,
        :trading_bazaar_sales,
        :trading_bazaar_profit,
        :trading_item_market_customers,
        :trading_item_market_sales,
        :trading_item_market_revenue,
        :trading_item_market_fees,

        # Jail
        :jail_times_jailed,
        :jail_busts_success,
        :jail_busts_fails,
        :jail_bails_amount,
        :jail_bails_fees,

        # Hospital
        :hospital_times_hospitalized,
        :hospital_medical_items_used,
        :hospital_blood_withdrawn,
        :hospital_reviving_skill,
        :hospital_reviving_revives,
        :hospital_reviving_revives_received,

        # Finishing hits
        :finishing_hits_heavy_artillery,
        :finishing_hits_machine_guns,
        :finishing_hits_rifles,
        :finishing_hits_sub_machine_guns,
        :finishing_hits_shotguns,
        :finishing_hits_pistols,
        :finishing_hits_temporary,
        :finishing_hits_piercing,
        :finishing_hits_slashing,
        :finishing_hits_clubbing,
        :finishing_hits_mechanical,
        :finishing_hits_hand_to_hand,

        # Communication
        :communication_mails_sent_total,
        :communication_mails_sent_friends,
        :communication_mails_sent_faction,
        :communication_mails_sent_colleagues,
        :communication_mails_sent_spouse,
        :communication_classified_ads,
        :communication_personals,

        # Crimes
        :crimes_offenses_vandalism,
        :crimes_offenses_fraud,
        :crimes_offenses_theft,
        :crimes_offenses_counterfeiting,
        :crimes_offenses_illicit_services,
        :crimes_offenses_cybercrime,
        :crimes_offenses_extortion,
        :crimes_offenses_illegal_production,
        :crimes_offenses_organized_crimes,
        :crimes_offenses_total,
        :crimes_skills_search_for_cash,
        :crimes_skills_bootlegging,
        :crimes_skills_graffiti,
        :crimes_skills_shoplifting,
        :crimes_skills_pickpocketing,
        :crimes_skills_card_skimming,
        :crimes_skills_burglary,
        :crimes_skills_hustling,
        :crimes_skills_disposal,
        :crimes_skills_cracking,
        :crimes_skills_forgery,
        :crimes_skills_scamming,
        :crimes_skills_arson,
        :crimes_total,
        :crimes_version,

        # Bounties
        :bounties_placed_amount,
        :bounties_placed_value,
        :bounties_collected_amount,
        :bounties_collected_value,
        :bounties_received_amount,
        :bounties_received_value,

        # Items
        :items_found_city,
        :items_found_dump,
        :items_found_easter_eggs,
        :items_trashed,
        :items_used_books,
        :items_used_boosters,
        :items_used_consumables,
        :items_used_candy,
        :items_used_alcohol,
        :items_used_energy,
        :items_used_energy_drinks,
        :items_used_stat_enhancers,
        :items_used_easter_eggs,
        :items_viruses_coded,

        # Travel
        :travel_total,
        :travel_time_spent,
        :travel_items_bought,
        :travel_hunting_skill,
        :travel_attacks_won,
        :travel_defends_lost,
        :travel_argentina,
        :travel_canada,
        :travel_cayman_islands,
        :travel_china,
        :travel_hawaii,
        :travel_japan,
        :travel_mexico,
        :travel_united_arab_emirates,
        :travel_united_kingdom,
        :travel_south_africa,
        :travel_switzerland,

        # Drugs
        :drugs_cannabis,
        :drugs_ecstasy,
        :drugs_ketamine,
        :drugs_lsd,
        :drugs_opium,
        :drugs_pcp,
        :drugs_shrooms,
        :drugs_speed,
        :drugs_vicodin,
        :drugs_xanax,
        :drugs_total,
        :drugs_overdoses,
        :drugs_rehabilitations_amount,
        :drugs_rehabilitations_fees,

        # Missions
        :missions_missions,
        :missions_contracts_total,
        :missions_contracts_duke,
        :missions_credits,

        # Racing
        :racing_skill,
        :racing_points,
        :racing_races_entered,
        :racing_races_won,

        # Networth
        :networth_total,

        # Other
        :other_activity_time,
        :other_activity_streak_current,
        :other_activity_streak_best,
        :other_awards,
        :other_merits_bought,
        :other_refills_energy,
        :other_refills_nerve,
        :other_refills_token,
        :other_donator_days,
        :other_ranked_war_wins
      )

      private

      def flatten_hash(hash, parent_key = '', out = {})
        hash.each do |k, v|
          key = parent_key.empty? ? k : "#{parent_key}_#{k}"
          if v.is_a?(Hash)
            flatten_hash(v, key, out)
          else
            out[key.to_sym] = v
          end
        end
        out
      end

      def parse_personalstats(stats)
        flat_stats = flatten_hash(stats)
        PersonalStatSnapshot.new(**flat_stats)
      end
    end
  end
end
