class CleanupPersonalStatSnapshots < ActiveRecord::Migration[8.1]
  def change
    # Remove all unused columns - keeping only:
    # - user_id, created_at, updated_at, timestamp
    # - drugs_xanax, drugs_cannabis
    # - other_refills_energy, other_refills_nerve
    # - items_used_boosters, items_used_stat_enhancers
    # - missions_contracts_total, crimes_offenses_total
    # - other_activity_time, networth_total
    # - attacking_networth_money_mugged

    columns_to_remove = %w[
      attacking_ammunition_hollow_point attacking_ammunition_incendiary
      attacking_ammunition_piercing attacking_ammunition_special
      attacking_ammunition_total attacking_ammunition_tracer
      attacking_attacks_assist attacking_attacks_lost attacking_attacks_stalemate
      attacking_attacks_stealth attacking_attacks_won attacking_damage_best
      attacking_damage_total attacking_defends_lost attacking_defends_stalemate
      attacking_defends_total attacking_defends_won attacking_elo
      attacking_escapes_foes attacking_escapes_player attacking_faction_raid_hits
      attacking_faction_ranked_war_hits attacking_faction_respect
      attacking_faction_retaliations attacking_faction_territory_wall_clears
      attacking_faction_territory_wall_joins attacking_faction_territory_wall_time
      attacking_highest_level_beaten attacking_hits_critical attacking_hits_miss
      attacking_hits_one_hit_kills attacking_hits_success attacking_killstreak_best
      attacking_networth_items_looted attacking_networth_largest_mug
      attacking_unarmored_wins bounties_collected_amount bounties_collected_value
      bounties_placed_amount bounties_placed_value bounties_received_amount
      bounties_received_value communication_classified_ads
      communication_mails_sent_colleagues communication_mails_sent_faction
      communication_mails_sent_friends communication_mails_sent_spouse
      communication_mails_sent_total communication_personals
      crimes_offenses_counterfeiting crimes_offenses_cybercrime
      crimes_offenses_extortion crimes_offenses_fraud
      crimes_offenses_illegal_production crimes_offenses_illicit_services
      crimes_offenses_organized_crimes crimes_offenses_theft crimes_offenses_vandalism
      crimes_skills_arson crimes_skills_bootlegging crimes_skills_burglary
      crimes_skills_card_skimming crimes_skills_cracking crimes_skills_disposal
      crimes_skills_forgery crimes_skills_graffiti crimes_skills_hustling
      crimes_skills_pickpocketing crimes_skills_scamming crimes_skills_search_for_cash
      crimes_skills_shoplifting crimes_total crimes_version
      drugs_ecstasy drugs_ketamine drugs_lsd drugs_opium drugs_overdoses drugs_pcp
      drugs_rehabilitations_amount drugs_rehabilitations_fees drugs_shrooms
      drugs_speed drugs_total drugs_vicodin
      finishing_hits_clubbing finishing_hits_hand_to_hand finishing_hits_heavy_artillery
      finishing_hits_machine_guns finishing_hits_mechanical finishing_hits_piercing
      finishing_hits_pistols finishing_hits_rifles finishing_hits_shotguns
      finishing_hits_slashing finishing_hits_sub_machine_guns finishing_hits_temporary
      hospital_blood_withdrawn hospital_medical_items_used hospital_reviving_revives
      hospital_reviving_revives_received hospital_reviving_skill hospital_times_hospitalized
      items_found_city items_found_dump items_found_easter_eggs items_trashed
      items_used_alcohol items_used_books items_used_candy items_used_consumables
      items_used_easter_eggs items_used_energy items_used_energy_drinks items_viruses_coded
      jail_bails_amount jail_bails_fees jail_busts_fails jail_busts_success jail_times_jailed
      jobs_job_points_used jobs_trains_received missions_contracts_duke missions_credits
      missions_missions other_activity_streak_best other_activity_streak_current
      other_awards other_donator_days other_merits_bought other_ranked_war_wins
      other_refills_token racing_points racing_races_entered racing_races_won racing_skill
      trading_bazaar_customers trading_bazaar_profit trading_bazaar_sales
      trading_item_market_customers trading_item_market_fees trading_item_market_revenue
      trading_item_market_sales trading_items_auctions_sold trading_items_auctions_won
      trading_items_bought_market trading_items_bought_shops trading_items_sent
      trading_points_bought trading_points_sold trading_trades
      travel_argentina travel_attacks_won travel_canada travel_cayman_islands
      travel_china travel_defends_lost travel_hawaii travel_hunting_skill
      travel_items_bought travel_japan travel_mexico travel_south_africa
      travel_switzerland travel_time_spent travel_total travel_united_arab_emirates
      travel_united_kingdom
    ]

    columns_to_remove.each do |column|
      remove_column :personal_stat_snapshots, column, if_exists: true
    end

    # Add date column populated from existing timestamp data
    add_column :personal_stat_snapshots, :date, :date

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE personal_stat_snapshots
          SET date = date(timestamp, 'unixepoch')
        SQL
      end
    end

    change_column_null :personal_stat_snapshots, :date, false

    # Replace old unique index with new one on date
    # Keep timestamp column but make it nullable (for audit/logging)
    remove_index :personal_stat_snapshots, [ :user_id, :timestamp ]
    change_column_null :personal_stat_snapshots, :timestamp, true
    add_index :personal_stat_snapshots, [ :user_id, :date ], unique: true
  end
end
