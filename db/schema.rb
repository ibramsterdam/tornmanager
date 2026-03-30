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

ActiveRecord::Schema[8.1].define(version: 2026_03_30_194240) do
  create_table "api_calls", force: :cascade do |t|
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.text "error_message"
    t.integer "faction_id"
    t.integer "response_time"
    t.string "selections"
    t.string "status", null: false
    t.integer "torn_api_timestamp"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_api_calls_on_created_at"
    t.index ["faction_id"], name: "index_api_calls_on_faction_id"
    t.index ["user_id", "created_at"], name: "index_api_calls_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_api_calls_on_user_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.string "access_type"
    t.datetime "created_at", null: false
    t.boolean "faction_access", default: false, null: false
    t.integer "faction_id", null: false
    t.string "key", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["faction_id", "type"], name: "index_api_keys_on_faction_id_and_type", unique: true
    t.index ["faction_id"], name: "index_api_keys_on_faction_id"
  end

  create_table "faction_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "faction_id", null: false
    t.datetime "updated_at", null: false
    t.index ["faction_id"], name: "index_faction_settings_on_faction_id", unique: true
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
    t.datetime "backfill_ends_at"
    t.date "backfill_target_date"
    t.datetime "created_at", null: false
    t.decimal "energy_refill_target", default: "0.0", null: false
    t.string "name", null: false
    t.decimal "nerve_refill_target", default: "0.0", null: false
    t.boolean "public_wars", default: false, null: false
    t.boolean "setup_completed", default: true, null: false
    t.integer "torn_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "war_polling_active", default: false, null: false
    t.decimal "xanax_target", default: "2.5", null: false
    t.index ["torn_id"], name: "index_factions_on_torn_id", unique: true
  end

  create_table "personal_stat_snapshots", force: :cascade do |t|
    t.integer "attacking_networth_money_mugged"
    t.datetime "created_at", null: false
    t.integer "crimes_offenses_total"
    t.date "date", null: false
    t.integer "drugs_xanax"
    t.integer "items_used_boosters"
    t.integer "items_used_energy_drinks"
    t.integer "items_used_stat_enhancers"
    t.integer "missions_contracts_total"
    t.bigint "networth_total"
    t.integer "other_activity_time"
    t.integer "other_refills_energy"
    t.integer "other_refills_nerve"
    t.integer "timestamp"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "date"], name: "index_personal_stat_snapshots_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_personal_stat_snapshots_on_user_id"
  end

  create_table "public_war_lobbies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by_name", null: false
    t.integer "created_by_torn_id", null: false
    t.string "faction_name", null: false
    t.integer "faction_torn_id", null: false
    t.string "opponent_faction_name", null: false
    t.string "password_digest"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_public_war_lobbies_on_slug", unique: true
  end

  create_table "ranked_wars", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.integer "faction_id", null: false
    t.boolean "forfeit", default: false, null: false
    t.integer "opponent_faction_id", null: false
    t.string "opponent_faction_name", null: false
    t.integer "our_attacks", default: 0, null: false
    t.json "our_members", default: []
    t.json "our_rewards", default: {}
    t.integer "our_score", default: 0, null: false
    t.integer "points_gained", default: 0, null: false
    t.string "rank_after"
    t.string "rank_before"
    t.integer "respect_gained", default: 0, null: false
    t.datetime "started_at", null: false
    t.integer "target_score", null: false
    t.integer "their_attacks", default: 0, null: false
    t.json "their_members", default: []
    t.json "their_rewards", default: {}
    t.integer "their_score", default: 0, null: false
    t.integer "torn_war_id", null: false
    t.datetime "updated_at", null: false
    t.integer "winner_faction_id"
    t.index ["faction_id", "started_at"], name: "index_ranked_wars_on_faction_id_and_started_at"
    t.index ["faction_id", "torn_war_id"], name: "index_ranked_wars_on_faction_id_and_torn_war_id", unique: true
    t.index ["faction_id"], name: "index_ranked_wars_on_faction_id"
  end

  create_table "recon_training_samples", force: :cascade do |t|
    t.integer "attackswon"
    t.integer "awards"
    t.integer "boostersused"
    t.datetime "created_at", null: false
    t.integer "daysbeendonator"
    t.bigint "defense", null: false
    t.bigint "dexterity", null: false
    t.integer "energydrinkused"
    t.integer "exttaken"
    t.integer "highestbeaten"
    t.integer "hospital"
    t.integer "jobpointsused"
    t.integer "level"
    t.integer "lsdtaken"
    t.bigint "networth"
    t.integer "player_id", null: false
    t.integer "property_happy"
    t.integer "real_age"
    t.integer "refills"
    t.integer "rehabs"
    t.integer "revives"
    t.bigint "speed", null: false
    t.date "spied_at", null: false
    t.integer "statenhancersused"
    t.bigint "strength", null: false
    t.integer "trainsreceived"
    t.datetime "updated_at", null: false
    t.integer "useractivity"
    t.integer "victaken"
    t.integer "xantaken"
    t.index ["player_id", "spied_at"], name: "index_recon_training_samples_on_player_id_and_spied_at", unique: true
    t.index ["player_id"], name: "index_recon_training_samples_on_player_id"
    t.index ["spied_at"], name: "index_recon_training_samples_on_spied_at"
  end

  create_table "roadmap_items", force: :cascade do |t|
    t.string "category", default: "factions", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.string "status", default: "planned", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["status", "position"], name: "index_roadmap_items_on_status_and_position"
  end

  create_table "script_versions", force: :cascade do |t|
    t.text "changelog"
    t.datetime "created_at", null: false
    t.date "released_at", null: false
    t.text "script_content"
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["version"], name: "index_script_versions_on_version", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "spy_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "defense"
    t.bigint "dexterity"
    t.integer "faction_id", null: false
    t.bigint "speed"
    t.datetime "spied_at"
    t.bigint "strength"
    t.integer "torn_id", null: false
    t.bigint "total"
    t.datetime "updated_at", null: false
    t.index ["faction_id", "torn_id"], name: "index_spy_reports_on_faction_id_and_torn_id", unique: true
    t.index ["faction_id"], name: "index_spy_reports_on_faction_id"
    t.index ["torn_id"], name: "index_spy_reports_on_torn_id"
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
    t.datetime "backfill_ends_at"
    t.datetime "created_at", null: false
    t.integer "faction_id"
    t.boolean "fallen", default: false, null: false
    t.boolean "hof_stats_user", default: false, null: false
    t.boolean "leadership_access", default: false, null: false
    t.integer "level", null: false
    t.string "name", null: false
    t.string "position"
    t.string "profile_image"
    t.boolean "ssl_user", default: false, null: false
    t.datetime "subscription_expires_at"
    t.integer "torn_id", null: false
    t.datetime "trial_granted_at"
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

  add_foreign_key "faction_subscription_grants", "factions"
  add_foreign_key "faction_subscription_grants", "users", column: "granted_by_id"
  add_foreign_key "personal_stat_snapshots", "users"
  add_foreign_key "personal_stat_snapshots", "users"
  add_foreign_key "ranked_wars", "factions"
  add_foreign_key "sessions", "users"
  add_foreign_key "spy_reports", "factions"
  add_foreign_key "subscription_grants", "faction_subscription_grants"
  add_foreign_key "subscription_grants", "users"
  add_foreign_key "users", "factions"
  add_foreign_key "xanax_payments", "users", column: "recipient_id"
  add_foreign_key "xanax_payments", "users", column: "sender_id"
end
