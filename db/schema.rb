# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_16_200710) do
  create_table "api_calls", force: :cascade do |t|
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.text "error_message"
    t.integer "response_time"
    t.string "selections"
    t.string "status", null: false
    t.integer "torn_api_timestamp"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_api_calls_on_created_at"
    t.index ["user_id", "created_at"], name: "index_api_calls_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_api_calls_on_user_id"
  end

  create_table "faction_subscription_grants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "faction_id"
    t.string "faction_name", null: false
    t.datetime "granted_at", null: false
    t.integer "granted_by_id", null: false
    t.integer "torn_faction_id", null: false
    t.datetime "updated_at", null: false
    t.integer "weeks_granted", null: false
    t.index ["faction_id"], name: "index_faction_subscription_grants_on_faction_id"
    t.index ["granted_by_id"], name: "index_faction_subscription_grants_on_granted_by_id"
    t.index ["torn_faction_id"], name: "index_faction_subscription_grants_on_torn_faction_id"
  end

  create_table "factions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "energy_refill_target", default: "1.0", null: false
    t.string "name", null: false
    t.decimal "nerve_refill_target", default: "1.0", null: false
    t.integer "torn_id", null: false
    t.boolean "track_stats", default: false, null: false
    t.datetime "updated_at", null: false
    t.decimal "xanax_target", default: "2.5", null: false
    t.index ["torn_id"], name: "index_factions_on_torn_id", unique: true
    t.index ["track_stats"], name: "index_factions_on_track_stats"
  end

  create_table "personal_stat_snapshots", force: :cascade do |t|
    t.integer "attacking_ammunition_hollow_point"
    t.integer "attacking_ammunition_incendiary"
    t.integer "attacking_ammunition_piercing"
    t.integer "attacking_ammunition_special"
    t.integer "attacking_ammunition_total"
    t.integer "attacking_ammunition_tracer"
    t.integer "attacking_attacks_assist"
    t.integer "attacking_attacks_lost"
    t.integer "attacking_attacks_stalemate"
    t.integer "attacking_attacks_stealth"
    t.integer "attacking_attacks_won"
    t.integer "attacking_damage_best"
    t.integer "attacking_damage_total"
    t.integer "attacking_defends_lost"
    t.integer "attacking_defends_stalemate"
    t.integer "attacking_defends_total"
    t.integer "attacking_defends_won"
    t.integer "attacking_elo"
    t.integer "attacking_escapes_foes"
    t.integer "attacking_escapes_player"
    t.integer "attacking_faction_raid_hits"
    t.integer "attacking_faction_ranked_war_hits"
    t.integer "attacking_faction_respect"
    t.integer "attacking_faction_retaliations"
    t.integer "attacking_faction_territory_wall_clears"
    t.integer "attacking_faction_territory_wall_joins"
    t.integer "attacking_faction_territory_wall_time"
    t.integer "attacking_highest_level_beaten"
    t.integer "attacking_hits_critical"
    t.integer "attacking_hits_miss"
    t.integer "attacking_hits_one_hit_kills"
    t.integer "attacking_hits_success"
    t.integer "attacking_killstreak_best"
    t.integer "attacking_networth_items_looted"
    t.integer "attacking_networth_largest_mug"
    t.integer "attacking_networth_money_mugged"
    t.integer "attacking_unarmored_wins"
    t.integer "bounties_collected_amount"
    t.integer "bounties_collected_value"
    t.integer "bounties_placed_amount"
    t.integer "bounties_placed_value"
    t.integer "bounties_received_amount"
    t.integer "bounties_received_value"
    t.integer "communication_classified_ads"
    t.integer "communication_mails_sent_colleagues"
    t.integer "communication_mails_sent_faction"
    t.integer "communication_mails_sent_friends"
    t.integer "communication_mails_sent_spouse"
    t.integer "communication_mails_sent_total"
    t.integer "communication_personals"
    t.datetime "created_at", null: false
    t.integer "crimes_offenses_counterfeiting"
    t.integer "crimes_offenses_cybercrime"
    t.integer "crimes_offenses_extortion"
    t.integer "crimes_offenses_fraud"
    t.integer "crimes_offenses_illegal_production"
    t.integer "crimes_offenses_illicit_services"
    t.integer "crimes_offenses_organized_crimes"
    t.integer "crimes_offenses_theft"
    t.integer "crimes_offenses_total"
    t.integer "crimes_offenses_vandalism"
    t.integer "crimes_skills_arson"
    t.integer "crimes_skills_bootlegging"
    t.integer "crimes_skills_burglary"
    t.integer "crimes_skills_card_skimming"
    t.integer "crimes_skills_cracking"
    t.integer "crimes_skills_disposal"
    t.integer "crimes_skills_forgery"
    t.integer "crimes_skills_graffiti"
    t.integer "crimes_skills_hustling"
    t.integer "crimes_skills_pickpocketing"
    t.integer "crimes_skills_scamming"
    t.integer "crimes_skills_search_for_cash"
    t.integer "crimes_skills_shoplifting"
    t.integer "crimes_total"
    t.string "crimes_version"
    t.date "date"
    t.integer "drugs_cannabis"
    t.integer "drugs_ecstasy"
    t.integer "drugs_ketamine"
    t.integer "drugs_lsd"
    t.integer "drugs_opium"
    t.integer "drugs_overdoses"
    t.integer "drugs_pcp"
    t.integer "drugs_rehabilitations_amount"
    t.integer "drugs_rehabilitations_fees"
    t.integer "drugs_shrooms"
    t.integer "drugs_speed"
    t.integer "drugs_total"
    t.integer "drugs_vicodin"
    t.integer "drugs_xanax"
    t.integer "finishing_hits_clubbing"
    t.integer "finishing_hits_hand_to_hand"
    t.integer "finishing_hits_heavy_artillery"
    t.integer "finishing_hits_machine_guns"
    t.integer "finishing_hits_mechanical"
    t.integer "finishing_hits_piercing"
    t.integer "finishing_hits_pistols"
    t.integer "finishing_hits_rifles"
    t.integer "finishing_hits_shotguns"
    t.integer "finishing_hits_slashing"
    t.integer "finishing_hits_sub_machine_guns"
    t.integer "finishing_hits_temporary"
    t.integer "hospital_blood_withdrawn"
    t.integer "hospital_medical_items_used"
    t.integer "hospital_reviving_revives"
    t.integer "hospital_reviving_revives_received"
    t.integer "hospital_reviving_skill"
    t.integer "hospital_times_hospitalized"
    t.integer "items_found_city"
    t.integer "items_found_dump"
    t.integer "items_found_easter_eggs"
    t.integer "items_trashed"
    t.integer "items_used_alcohol"
    t.integer "items_used_books"
    t.integer "items_used_boosters"
    t.integer "items_used_candy"
    t.integer "items_used_consumables"
    t.integer "items_used_easter_eggs"
    t.integer "items_used_energy"
    t.integer "items_used_energy_drinks"
    t.integer "items_used_stat_enhancers"
    t.integer "items_viruses_coded"
    t.integer "jail_bails_amount"
    t.bigint "jail_bails_fees"
    t.integer "jail_busts_fails"
    t.integer "jail_busts_success"
    t.integer "jail_times_jailed"
    t.integer "jobs_job_points_used"
    t.integer "jobs_trains_received"
    t.integer "missions_contracts_duke"
    t.integer "missions_contracts_total"
    t.integer "missions_credits"
    t.integer "missions_missions"
    t.bigint "networth_total"
    t.integer "other_activity_streak_best"
    t.integer "other_activity_streak_current"
    t.integer "other_activity_time"
    t.integer "other_awards"
    t.integer "other_donator_days"
    t.integer "other_merits_bought"
    t.integer "other_ranked_war_wins"
    t.integer "other_refills_energy"
    t.integer "other_refills_nerve"
    t.integer "other_refills_token"
    t.integer "racing_points"
    t.integer "racing_races_entered"
    t.integer "racing_races_won"
    t.integer "racing_skill"
    t.integer "trading_bazaar_customers"
    t.bigint "trading_bazaar_profit"
    t.integer "trading_bazaar_sales"
    t.integer "trading_item_market_customers"
    t.bigint "trading_item_market_fees"
    t.bigint "trading_item_market_revenue"
    t.integer "trading_item_market_sales"
    t.integer "trading_items_auctions_sold"
    t.integer "trading_items_auctions_won"
    t.integer "trading_items_bought_market"
    t.integer "trading_items_bought_shops"
    t.integer "trading_items_sent"
    t.integer "trading_points_bought"
    t.integer "trading_points_sold"
    t.integer "trading_trades"
    t.integer "travel_argentina"
    t.integer "travel_attacks_won"
    t.integer "travel_canada"
    t.integer "travel_cayman_islands"
    t.integer "travel_china"
    t.integer "travel_defends_lost"
    t.integer "travel_hawaii"
    t.integer "travel_hunting_skill"
    t.integer "travel_items_bought"
    t.integer "travel_japan"
    t.integer "travel_mexico"
    t.integer "travel_south_africa"
    t.integer "travel_switzerland"
    t.integer "travel_time_spent"
    t.integer "travel_total"
    t.integer "travel_united_arab_emirates"
    t.integer "travel_united_kingdom"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "date"], name: "index_personal_stat_snapshots_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_personal_stat_snapshots_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscription_grants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "faction_subscription_grant_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["faction_subscription_grant_id", "user_id"], name: "index_faction_grant_users_on_grant_and_user", unique: true
    t.index ["faction_subscription_grant_id"], name: "index_subscription_grants_on_faction_subscription_grant_id"
    t.index ["user_id"], name: "index_subscription_grants_on_user_id"
  end

  create_table "torn_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "market_price"
    t.string "name", null: false
    t.integer "torn_id", null: false
    t.datetime "updated_at", null: false
    t.index ["torn_id"], name: "index_torn_items_on_torn_id", unique: true
  end

  create_table "torn_stocks", force: :cascade do |t|
    t.string "acronym", null: false
    t.datetime "created_at", null: false
    t.decimal "current_price", null: false
    t.string "dividend_description", null: false
    t.integer "dividend_frequency"
    t.integer "dividend_requirement", null: false
    t.integer "dividend_value", default: 0, null: false
    t.integer "integer", default: 0, null: false
    t.string "name", null: false
    t.integer "torn_id", null: false
    t.datetime "updated_at", null: false
    t.index ["torn_id"], name: "index_torn_stocks_on_torn_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "api_access_type"
    t.string "api_key"
    t.datetime "created_at", null: false
    t.integer "faction_id"
    t.boolean "hof_stats_user", default: false, null: false
    t.integer "level", null: false
    t.string "name", null: false
    t.string "profile_image"
    t.datetime "subscription_expires_at"
    t.integer "torn_id", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["faction_id"], name: "index_users_on_faction_id"
    t.index ["hof_stats_user"], name: "index_users_on_hof_stats_user"
    t.index ["subscription_expires_at"], name: "index_users_on_subscription_expires_at"
    t.index ["torn_id"], name: "index_users_on_torn_id", unique: true
  end

  create_table "xanax_payments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "log_id", null: false
    t.datetime "processed_at", null: false
    t.integer "recipient_id", null: false
    t.integer "sender_id", null: false
    t.datetime "updated_at", null: false
    t.integer "weeks_granted", null: false
    t.integer "xanax_amount", null: false
    t.index ["log_id"], name: "index_xanax_payments_on_log_id", unique: true
    t.index ["recipient_id"], name: "index_xanax_payments_on_recipient_id"
    t.index ["sender_id"], name: "index_xanax_payments_on_sender_id"
  end

  add_foreign_key "api_calls", "users"
  add_foreign_key "faction_subscription_grants", "factions"
  add_foreign_key "faction_subscription_grants", "users", column: "granted_by_id"
  add_foreign_key "personal_stat_snapshots", "users"
  add_foreign_key "personal_stat_snapshots", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscription_grants", "faction_subscription_grants"
  add_foreign_key "subscription_grants", "users"
  add_foreign_key "users", "factions"
  add_foreign_key "xanax_payments", "users", column: "recipient_id"
  add_foreign_key "xanax_payments", "users", column: "sender_id"
end
