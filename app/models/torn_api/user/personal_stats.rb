module TornApi
  module User
    class PersonalStats < Base
      attr_reader :torn_id
      PersonalStatSnapshot = Data.define(
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

      private

      def parse_personalstats(stats)
        PersonalStatSnapshot.new(
          # Attacking
          attacking_attacks_won: stats.dig("attacking", "attacks", "won"),
          attacking_attacks_lost: stats.dig("attacking", "attacks", "lost"),
          attacking_attacks_stalemate: stats.dig("attacking", "attacks", "stalemate"),
          attacking_attacks_assist: stats.dig("attacking", "attacks", "assist"),
          attacking_attacks_stealth: stats.dig("attacking", "attacks", "stealth"),
          attacking_defends_won: stats.dig("attacking", "defends", "won"),
          attacking_defends_lost: stats.dig("attacking", "defends", "lost"),
          attacking_defends_stalemate: stats.dig("attacking", "defends", "stalemate"),
          attacking_defends_total: stats.dig("attacking", "defends", "total"),
          attacking_elo: stats.dig("attacking", "elo"),
          attacking_unarmored_wins: stats.dig("attacking", "unarmored_wins"),
          attacking_highest_level_beaten: stats.dig("attacking", "highest_level_beaten"),
          attacking_escapes_player: stats.dig("attacking", "escapes", "player"),
          attacking_escapes_foes: stats.dig("attacking", "escapes", "foes"),
          attacking_killstreak_best: stats.dig("attacking", "killstreak", "best"),
          attacking_hits_success: stats.dig("attacking", "hits", "success"),
          attacking_hits_miss: stats.dig("attacking", "hits", "miss"),
          attacking_hits_critical: stats.dig("attacking", "hits", "critical"),
          attacking_hits_one_hit_kills: stats.dig("attacking", "hits", "one_hit_kills"),
          attacking_damage_total: stats.dig("attacking", "damage", "total"),
          attacking_damage_best: stats.dig("attacking", "damage", "best"),
          attacking_networth_money_mugged: stats.dig("attacking", "networth", "money_mugged"),
          attacking_networth_largest_mug: stats.dig("attacking", "networth", "largest_mug"),
          attacking_networth_items_looted: stats.dig("attacking", "networth", "items_looted"),
          attacking_ammunition_total: stats.dig("attacking", "ammunition", "total"),
          attacking_ammunition_special: stats.dig("attacking", "ammunition", "special"),
          attacking_ammunition_hollow_point: stats.dig("attacking", "ammunition", "hollow_point"),
          attacking_ammunition_tracer: stats.dig("attacking", "ammunition", "tracer"),
          attacking_ammunition_piercing: stats.dig("attacking", "ammunition", "piercing"),
          attacking_ammunition_incendiary: stats.dig("attacking", "ammunition", "incendiary"),
          attacking_faction_respect: stats.dig("attacking", "faction", "respect"),
          attacking_faction_retaliations: stats.dig("attacking", "faction", "retaliations"),
          attacking_faction_ranked_war_hits: stats.dig("attacking", "faction", "ranked_war_hits"),
          attacking_faction_raid_hits: stats.dig("attacking", "faction", "raid_hits"),
          attacking_faction_territory_wall_joins: stats.dig("attacking", "faction", "territory", "wall_joins"),
          attacking_faction_territory_wall_clears: stats.dig("attacking", "faction", "territory", "wall_clears"),
          attacking_faction_territory_wall_time: stats.dig("attacking", "faction", "territory", "wall_time"),

          # Jobs
          jobs_job_points_used: stats.dig("jobs", "job_points_used"),
          jobs_trains_received: stats.dig("jobs", "trains_received"),

          # Trading
          trading_items_bought_market: stats.dig("trading", "items", "bought", "market"),
          trading_items_bought_shops: stats.dig("trading", "items", "bought", "shops"),
          trading_items_auctions_won: stats.dig("trading", "items", "auctions", "won"),
          trading_items_auctions_sold: stats.dig("trading", "items", "auctions", "sold"),
          trading_items_sent: stats.dig("trading", "items", "sent"),
          trading_trades: stats.dig("trading", "trades"),
          trading_points_bought: stats.dig("trading", "points", "bought"),
          trading_points_sold: stats.dig("trading", "points", "sold"),
          trading_bazaar_customers: stats.dig("trading", "bazaar", "customers"),
          trading_bazaar_sales: stats.dig("trading", "bazaar", "sales"),
          trading_bazaar_profit: stats.dig("trading", "bazaar", "profit"),
          trading_item_market_customers: stats.dig("trading", "item_market", "customers"),
          trading_item_market_sales: stats.dig("trading", "item_market", "sales"),
          trading_item_market_revenue: stats.dig("trading", "item_market", "revenue"),
          trading_item_market_fees: stats.dig("trading", "item_market", "fees"),

          # Jail
          jail_times_jailed: stats.dig("jail", "times_jailed"),
          jail_busts_success: stats.dig("jail", "busts", "success"),
          jail_busts_fails: stats.dig("jail", "busts", "fails"),
          jail_bails_amount: stats.dig("jail", "bails", "amount"),
          jail_bails_fees: stats.dig("jail", "bails", "fees"),

          # Hospital
          hospital_times_hospitalized: stats.dig("hospital", "times_hospitalized"),
          hospital_medical_items_used: stats.dig("hospital", "medical_items_used"),
          hospital_blood_withdrawn: stats.dig("hospital", "blood_withdrawn"),
          hospital_reviving_skill: stats.dig("hospital", "reviving", "skill"),
          hospital_reviving_revives: stats.dig("hospital", "reviving", "revives"),
          hospital_reviving_revives_received: stats.dig("hospital", "reviving", "revives_received"),

          # Finishing hits
          finishing_hits_heavy_artillery: stats.dig("finishing_hits", "heavy_artillery"),
          finishing_hits_machine_guns: stats.dig("finishing_hits", "machine_guns"),
          finishing_hits_rifles: stats.dig("finishing_hits", "rifles"),
          finishing_hits_sub_machine_guns: stats.dig("finishing_hits", "sub_machine_guns"),
          finishing_hits_shotguns: stats.dig("finishing_hits", "shotguns"),
          finishing_hits_pistols: stats.dig("finishing_hits", "pistols"),
          finishing_hits_temporary: stats.dig("finishing_hits", "temporary"),
          finishing_hits_piercing: stats.dig("finishing_hits", "piercing"),
          finishing_hits_slashing: stats.dig("finishing_hits", "slashing"),
          finishing_hits_clubbing: stats.dig("finishing_hits", "clubbing"),
          finishing_hits_mechanical: stats.dig("finishing_hits", "mechanical"),
          finishing_hits_hand_to_hand: stats.dig("finishing_hits", "hand_to_hand"),

          # Communication
          communication_mails_sent_total: stats.dig("communication", "mails_sent", "total"),
          communication_mails_sent_friends: stats.dig("communication", "mails_sent", "friends"),
          communication_mails_sent_faction: stats.dig("communication", "mails_sent", "faction"),
          communication_mails_sent_colleagues: stats.dig("communication", "mails_sent", "colleagues"),
          communication_mails_sent_spouse: stats.dig("communication", "mails_sent", "spouse"),
          communication_classified_ads: stats.dig("communication", "classified_ads"),
          communication_personals: stats.dig("communication", "personals"),

          # Crimes
          crimes_offenses_vandalism: stats.dig("crimes", "offenses", "vandalism"),
          crimes_offenses_fraud: stats.dig("crimes", "offenses", "fraud"),
          crimes_offenses_theft: stats.dig("crimes", "offenses", "theft"),
          crimes_offenses_counterfeiting: stats.dig("crimes", "offenses", "counterfeiting"),
          crimes_offenses_illicit_services: stats.dig("crimes", "offenses", "illicit_services"),
          crimes_offenses_cybercrime: stats.dig("crimes", "offenses", "cybercrime"),
          crimes_offenses_extortion: stats.dig("crimes", "offenses", "extortion"),
          crimes_offenses_illegal_production: stats.dig("crimes", "offenses", "illegal_production"),
          crimes_offenses_organized_crimes: stats.dig("crimes", "offenses", "organized_crimes"),
          crimes_offenses_total: stats.dig("crimes", "offenses", "total"),
          crimes_skills_search_for_cash: stats.dig("crimes", "skills", "search_for_cash"),
          crimes_skills_bootlegging: stats.dig("crimes", "skills", "bootlegging"),
          crimes_skills_graffiti: stats.dig("crimes", "skills", "graffiti"),
          crimes_skills_shoplifting: stats.dig("crimes", "skills", "shoplifting"),
          crimes_skills_pickpocketing: stats.dig("crimes", "skills", "pickpocketing"),
          crimes_skills_card_skimming: stats.dig("crimes", "skills", "card_skimming"),
          crimes_skills_burglary: stats.dig("crimes", "skills", "burglary"),
          crimes_skills_hustling: stats.dig("crimes", "skills", "hustling"),
          crimes_skills_disposal: stats.dig("crimes", "skills", "disposal"),
          crimes_skills_cracking: stats.dig("crimes", "skills", "cracking"),
          crimes_skills_forgery: stats.dig("crimes", "skills", "forgery"),
          crimes_skills_scamming: stats.dig("crimes", "skills", "scamming"),
          crimes_skills_arson: stats.dig("crimes", "skills", "arson"),
          crimes_total: stats.dig("crimes", "total"),
          crimes_version: stats.dig("crimes", "version"),

          # Bounties
          bounties_placed_amount: stats.dig("bounties", "placed", "amount"),
          bounties_placed_value: stats.dig("bounties", "placed", "value"),
          bounties_collected_amount: stats.dig("bounties", "collected", "amount"),
          bounties_collected_value: stats.dig("bounties", "collected", "value"),
          bounties_received_amount: stats.dig("bounties", "received", "amount"),
          bounties_received_value: stats.dig("bounties", "received", "value"),

          # Items
          items_found_city: stats.dig("items", "found", "city"),
          items_found_dump: stats.dig("items", "found", "dump"),
          items_found_easter_eggs: stats.dig("items", "found", "easter_eggs"),
          items_trashed: stats.dig("items", "trashed"),
          items_used_books: stats.dig("items", "used", "books"),
          items_used_boosters: stats.dig("items", "used", "boosters"),
          items_used_consumables: stats.dig("items", "used", "consumables"),
          items_used_candy: stats.dig("items", "used", "candy"),
          items_used_alcohol: stats.dig("items", "used", "alcohol"),
          items_used_energy: stats.dig("items", "used", "energy"),
          items_used_energy_drinks: stats.dig("items", "used", "energy_drinks"),
          items_used_stat_enhancers: stats.dig("items", "used", "stat_enhancers"),
          items_used_easter_eggs: stats.dig("items", "used", "easter_eggs"),
          items_viruses_coded: stats.dig("items", "viruses_coded"),

          # Travel
          travel_total: stats.dig("travel", "total"),
          travel_time_spent: stats.dig("travel", "time_spent"),
          travel_items_bought: stats.dig("travel", "items_bought"),
          travel_hunting_skill: stats.dig("travel", "hunting", "skill"),
          travel_attacks_won: stats.dig("travel", "attacks_won"),
          travel_defends_lost: stats.dig("travel", "defends_lost"),
          travel_argentina: stats.dig("travel", "argentina"),
          travel_canada: stats.dig("travel", "canada"),
          travel_cayman_islands: stats.dig("travel", "cayman_islands"),
          travel_china: stats.dig("travel", "china"),
          travel_hawaii: stats.dig("travel", "hawaii"),
          travel_japan: stats.dig("travel", "japan"),
          travel_mexico: stats.dig("travel", "mexico"),
          travel_united_arab_emirates: stats.dig("travel", "united_arab_emirates"),
          travel_united_kingdom: stats.dig("travel", "united_kingdom"),
          travel_south_africa: stats.dig("travel", "south_africa"),
          travel_switzerland: stats.dig("travel", "switzerland"),

          # Drugs
          drugs_cannabis: stats.dig("drugs", "cannabis"),
          drugs_ecstasy: stats.dig("drugs", "ecstasy"),
          drugs_ketamine: stats.dig("drugs", "ketamine"),
          drugs_lsd: stats.dig("drugs", "lsd"),
          drugs_opium: stats.dig("drugs", "opium"),
          drugs_pcp: stats.dig("drugs", "pcp"),
          drugs_shrooms: stats.dig("drugs", "shrooms"),
          drugs_speed: stats.dig("drugs", "speed"),
          drugs_vicodin: stats.dig("drugs", "vicodin"),
          drugs_xanax: stats.dig("drugs", "xanax"),
          drugs_total: stats.dig("drugs", "total"),
          drugs_overdoses: stats.dig("drugs", "overdoses"),
          drugs_rehabilitations_amount: stats.dig("drugs", "rehabilitations", "amount"),
          drugs_rehabilitations_fees: stats.dig("drugs", "rehabilitations", "fees"),

          # Missions
          missions_missions: stats.dig("missions", "missions"),
          missions_contracts_total: stats.dig("missions", "contracts", "total"),
          missions_contracts_duke: stats.dig("missions", "contracts", "duke"),
          missions_credits: stats.dig("missions", "credits"),

          # Racing
          racing_skill: stats.dig("racing", "skill"),
          racing_points: stats.dig("racing", "points"),
          racing_races_entered: stats.dig("racing", "races", "entered"),
          racing_races_won: stats.dig("racing", "races", "won"),

          # Networth
          networth_total: stats.dig("networth", "total"),

          # Other
          other_activity_time: stats.dig("other", "activity", "time"),
          other_activity_streak_current: stats.dig("other", "activity", "streak", "current"),
          other_activity_streak_best: stats.dig("other", "activity", "streak", "best"),
          other_awards: stats.dig("other", "awards"),
          other_merits_bought: stats.dig("other", "merits_bought"),
          other_refills_energy: stats.dig("other", "refills", "energy"),
          other_refills_nerve: stats.dig("other", "refills", "nerve"),
          other_refills_token: stats.dig("other", "refills", "token"),
          other_donator_days: stats.dig("other", "donator_days"),
          other_ranked_war_wins: stats.dig("other", "ranked_war_wins")
        )
      end
    end
  end
end
