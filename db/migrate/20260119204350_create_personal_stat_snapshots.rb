class CreatePersonalStatSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :personal_stat_snapshots do |t|
      t.references :torn_user, null: false, foreign_key: true

      # Attacking
      t.integer :attacking_attacks_won
      t.integer :attacking_attacks_lost
      t.integer :attacking_attacks_stalemate
      t.integer :attacking_attacks_assist
      t.integer :attacking_attacks_stealth
      t.integer :attacking_defends_won
      t.integer :attacking_defends_lost
      t.integer :attacking_defends_stalemate
      t.integer :attacking_defends_total
      t.integer :attacking_elo
      t.integer :attacking_unarmored_wins
      t.integer :attacking_highest_level_beaten
      t.integer :attacking_escapes_player
      t.integer :attacking_escapes_foes
      t.integer :attacking_killstreak_best
      t.integer :attacking_hits_success
      t.integer :attacking_hits_miss
      t.integer :attacking_hits_critical
      t.integer :attacking_hits_one_hit_kills
      t.integer :attacking_damage_total
      t.integer :attacking_damage_best
      t.integer :attacking_networth_money_mugged
      t.integer :attacking_networth_largest_mug
      t.integer :attacking_networth_items_looted
      t.integer :attacking_ammunition_total
      t.integer :attacking_ammunition_special
      t.integer :attacking_ammunition_hollow_point
      t.integer :attacking_ammunition_tracer
      t.integer :attacking_ammunition_piercing
      t.integer :attacking_ammunition_incendiary
      t.integer :attacking_faction_respect
      t.integer :attacking_faction_retaliations
      t.integer :attacking_faction_ranked_war_hits
      t.integer :attacking_faction_raid_hits
      t.integer :attacking_faction_territory_wall_joins
      t.integer :attacking_faction_territory_wall_clears
      t.integer :attacking_faction_territory_wall_time

      # Jobs
      t.integer :jobs_job_points_used
      t.integer :jobs_trains_received

      # Trading
      t.integer :trading_items_bought_market
      t.integer :trading_items_bought_shops
      t.integer :trading_items_auctions_won
      t.integer :trading_items_auctions_sold
      t.integer :trading_items_sent
      t.integer :trading_trades
      t.integer :trading_points_bought
      t.integer :trading_points_sold
      t.integer :trading_bazaar_customers
      t.integer :trading_bazaar_sales
      t.bigint  :trading_bazaar_profit
      t.integer :trading_item_market_customers
      t.integer :trading_item_market_sales
      t.bigint  :trading_item_market_revenue
      t.bigint  :trading_item_market_fees

      # Jail
      t.integer :jail_times_jailed
      t.integer :jail_busts_success
      t.integer :jail_busts_fails
      t.integer :jail_bails_amount
      t.bigint  :jail_bails_fees

      # Hospital
      t.integer :hospital_times_hospitalized
      t.integer :hospital_medical_items_used
      t.integer :hospital_blood_withdrawn
      t.integer :hospital_reviving_skill
      t.integer :hospital_reviving_revives
      t.integer :hospital_reviving_revives_received

      # Finishing hits
      t.integer :finishing_hits_heavy_artillery
      t.integer :finishing_hits_machine_guns
      t.integer :finishing_hits_rifles
      t.integer :finishing_hits_sub_machine_guns
      t.integer :finishing_hits_shotguns
      t.integer :finishing_hits_pistols
      t.integer :finishing_hits_temporary
      t.integer :finishing_hits_piercing
      t.integer :finishing_hits_slashing
      t.integer :finishing_hits_clubbing
      t.integer :finishing_hits_mechanical
      t.integer :finishing_hits_hand_to_hand

      # Communication
      t.integer :communication_mails_sent_total
      t.integer :communication_mails_sent_friends
      t.integer :communication_mails_sent_faction
      t.integer :communication_mails_sent_colleagues
      t.integer :communication_mails_sent_spouse
      t.integer :communication_classified_ads
      t.integer :communication_personals

      # Crimes
      t.integer :crimes_offenses_vandalism
      t.integer :crimes_offenses_fraud
      t.integer :crimes_offenses_theft
      t.integer :crimes_offenses_counterfeiting
      t.integer :crimes_offenses_illicit_services
      t.integer :crimes_offenses_cybercrime
      t.integer :crimes_offenses_extortion
      t.integer :crimes_offenses_illegal_production
      t.integer :crimes_offenses_organized_crimes
      t.integer :crimes_offenses_total
      t.integer :crimes_skills_search_for_cash
      t.integer :crimes_skills_bootlegging
      t.integer :crimes_skills_graffiti
      t.integer :crimes_skills_shoplifting
      t.integer :crimes_skills_pickpocketing
      t.integer :crimes_skills_card_skimming
      t.integer :crimes_skills_burglary
      t.integer :crimes_skills_hustling
      t.integer :crimes_skills_disposal
      t.integer :crimes_skills_cracking
      t.integer :crimes_skills_forgery
      t.integer :crimes_skills_scamming
      t.integer :crimes_skills_arson
      t.integer :crimes_total
      t.string  :crimes_version

      # Bounties
      t.integer :bounties_placed_amount
      t.integer :bounties_placed_value
      t.integer :bounties_collected_amount
      t.integer :bounties_collected_value
      t.integer :bounties_received_amount
      t.integer :bounties_received_value

      # Items
      t.integer :items_found_city
      t.integer :items_found_dump
      t.integer :items_found_easter_eggs
      t.integer :items_trashed
      t.integer :items_used_books
      t.integer :items_used_boosters
      t.integer :items_used_consumables
      t.integer :items_used_candy
      t.integer :items_used_alcohol
      t.integer :items_used_energy
      t.integer :items_used_energy_drinks
      t.integer :items_used_stat_enhancers
      t.integer :items_used_easter_eggs
      t.integer :items_viruses_coded

      # Travel
      t.integer :travel_total
      t.integer :travel_time_spent
      t.integer :travel_items_bought
      t.integer :travel_hunting_skill
      t.integer :travel_attacks_won
      t.integer :travel_defends_lost
      t.integer :travel_argentina
      t.integer :travel_canada
      t.integer :travel_cayman_islands
      t.integer :travel_china
      t.integer :travel_hawaii
      t.integer :travel_japan
      t.integer :travel_mexico
      t.integer :travel_united_arab_emirates
      t.integer :travel_united_kingdom
      t.integer :travel_south_africa
      t.integer :travel_switzerland

      # Drugs
      t.integer :drugs_cannabis
      t.integer :drugs_ecstasy
      t.integer :drugs_ketamine
      t.integer :drugs_lsd
      t.integer :drugs_opium
      t.integer :drugs_pcp
      t.integer :drugs_shrooms
      t.integer :drugs_speed
      t.integer :drugs_vicodin
      t.integer :drugs_xanax
      t.integer :drugs_total
      t.integer :drugs_overdoses
      t.integer :drugs_rehabilitations_amount
      t.integer :drugs_rehabilitations_fees

      # Missions
      t.integer :missions_missions
      t.integer :missions_contracts_total
      t.integer :missions_contracts_duke
      t.integer :missions_credits

      # Racing
      t.integer :racing_skill
      t.integer :racing_points
      t.integer :racing_races_entered
      t.integer :racing_races_won

      # Networth
      t.bigint :networth_total

      # Other
      t.integer :other_activity_time
      t.integer :other_activity_streak_current
      t.integer :other_activity_streak_best
      t.integer :other_awards
      t.integer :other_merits_bought
      t.integer :other_refills_energy
      t.integer :other_refills_nerve
      t.integer :other_refills_token
      t.integer :other_donator_days
      t.integer :other_ranked_war_wins

      t.timestamps
    end
  end
end
