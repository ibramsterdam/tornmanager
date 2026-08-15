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

ActiveRecord::Schema[8.1].define(version: 2026_08_15_120000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.index ["api_key", "created_at"], name: "index_api_calls_on_api_key_and_created_at"
    t.index ["created_at"], name: "index_api_calls_on_created_at"
    t.index ["faction_id"], name: "index_api_calls_on_faction_id"
    t.index ["user_id", "created_at"], name: "index_api_calls_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_api_calls_on_user_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.string "access_type"
    t.datetime "created_at", null: false
    t.boolean "faction_access", default: false, null: false
    t.integer "faction_id"
    t.string "key", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["faction_id", "type"], name: "index_api_keys_on_faction_id_and_type", unique: true
    t.index ["faction_id"], name: "index_api_keys_on_faction_id"
    t.index ["user_id", "type"], name: "index_api_keys_on_user_id_and_type", unique: true, where: "user_id IS NOT NULL"
  end

  create_table "armory_news_entries", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.integer "faction_id", null: false
    t.string "item"
    t.datetime "occurred_at", null: false
    t.integer "player_id"
    t.string "player_name"
    t.text "text"
    t.string "torn_news_id", null: false
    t.index ["faction_id", "occurred_at"], name: "index_armory_news_entries_on_faction_id_and_occurred_at"
    t.index ["faction_id", "player_id", "action"], name: "idx_on_faction_id_player_id_action_86316add96"
    t.index ["faction_id", "torn_news_id"], name: "index_armory_news_entries_on_faction_id_and_torn_news_id", unique: true
    t.index ["faction_id"], name: "index_armory_news_entries_on_faction_id"
    t.index ["occurred_at"], name: "index_armory_news_entries_on_occurred_at"
  end

  create_table "chat_memberships", force: :cascade do |t|
    t.integer "chat_room_id", null: false
    t.datetime "created_at", null: false
    t.boolean "host", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["chat_room_id", "user_id"], name: "index_chat_memberships_on_chat_room_id_and_user_id", unique: true
    t.index ["chat_room_id"], name: "index_chat_memberships_on_chat_room_id"
    t.index ["user_id"], name: "index_chat_memberships_on_user_id"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.string "body", null: false
    t.integer "chat_room_id", null: false
    t.datetime "created_at", null: false
    t.string "sender_name"
    t.integer "sender_torn_id"
    t.boolean "system", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["chat_room_id"], name: "index_chat_messages_on_chat_room_id"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.boolean "anonymous", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "emptied_at"
    t.boolean "encrypted", default: false, null: false
    t.integer "host_user_id"
    t.string "invite_token", null: false
    t.string "kind", default: "private", null: false
    t.datetime "last_message_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["emptied_at"], name: "index_chat_rooms_on_emptied_at"
    t.index ["host_user_id"], name: "index_chat_rooms_on_host_user_id"
    t.index ["invite_token"], name: "index_chat_rooms_on_invite_token", unique: true
    t.index ["kind"], name: "index_chat_rooms_on_kind"
  end

  create_table "chat_suspensions", force: :cascade do |t|
    t.integer "chat_room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["chat_room_id", "user_id"], name: "index_chat_suspensions_on_chat_room_id_and_user_id", unique: true
    t.index ["chat_room_id"], name: "index_chat_suspensions_on_chat_room_id"
    t.index ["user_id"], name: "index_chat_suspensions_on_user_id"
  end

  create_table "faction_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "faction_id", null: false
    t.decimal "payout_assist_value", default: "0.75", null: false
    t.decimal "payout_faction_cut", default: "10.0", null: false
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
    t.boolean "armory_backfill_pending", default: false, null: false
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

  create_table "member_activity_snapshots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.integer "faction_id", null: false
    t.integer "hour_utc", null: false
    t.string "member_name", null: false
    t.datetime "recorded_at", null: false
    t.string "status", null: false
    t.integer "torn_member_id", null: false
    t.datetime "updated_at", null: false
    t.index ["faction_id", "hour_utc", "day_of_week"], name: "idx_activity_heatmap"
    t.index ["faction_id", "recorded_at"], name: "index_member_activity_snapshots_on_faction_id_and_recorded_at"
    t.index ["faction_id", "torn_member_id", "recorded_at"], name: "idx_activity_faction_member_time"
    t.index ["faction_id"], name: "index_member_activity_snapshots_on_faction_id"
    t.index ["recorded_at"], name: "index_member_activity_snapshots_on_recorded_at"
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
    t.boolean "torn_data_missing", default: false, null: false
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

  create_table "ranked_war_attacks", force: :cascade do |t|
    t.integer "attacker_faction_id"
    t.string "attacker_faction_name"
    t.integer "attacker_id", null: false
    t.integer "attacker_level"
    t.string "attacker_name"
    t.integer "chain", default: 0
    t.float "chain_modifier"
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "defender_faction_id"
    t.string "defender_faction_name"
    t.integer "defender_id", null: false
    t.integer "defender_level"
    t.string "defender_name"
    t.integer "ended", null: false
    t.float "fair_fight"
    t.json "finishing_hit_effects", default: []
    t.float "group_modifier"
    t.boolean "is_interrupted", default: false
    t.boolean "is_raid", default: false
    t.boolean "is_stealthed", default: false
    t.float "overseas"
    t.integer "ranked_war_id", null: false
    t.float "respect_gain", default: 0.0
    t.float "respect_loss", default: 0.0
    t.string "result", null: false
    t.float "retaliation"
    t.integer "started", null: false
    t.integer "torn_attack_id", null: false
    t.datetime "updated_at", null: false
    t.float "war"
    t.float "warlord"
    t.index ["attacker_id"], name: "index_ranked_war_attacks_on_attacker_id"
    t.index ["defender_id"], name: "index_ranked_war_attacks_on_defender_id"
    t.index ["ranked_war_id", "torn_attack_id"], name: "index_ranked_war_attacks_on_ranked_war_id_and_torn_attack_id", unique: true
    t.index ["ranked_war_id"], name: "index_ranked_war_attacks_on_ranked_war_id"
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
    t.integer "reward_estimated_value", limit: 8
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

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "subscribable_id", null: false
    t.string "subscribable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["subscribable_type", "subscribable_id"], name: "index_subscriptions_on_subscribable_type_and_subscribable_id", unique: true
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
    t.datetime "backfill_ends_at"
    t.datetime "banned_until"
    t.string "chat_anon_name"
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
    t.index ["banned_until"], name: "index_users_on_banned_until"
    t.index ["chat_anon_name"], name: "index_users_on_chat_anon_name", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "armory_news_entries", "factions"
  add_foreign_key "chat_memberships", "chat_rooms"
  add_foreign_key "chat_memberships", "users"
  add_foreign_key "chat_messages", "chat_rooms"
  add_foreign_key "chat_messages", "users"
  add_foreign_key "chat_rooms", "users", column: "host_user_id"
  add_foreign_key "chat_suspensions", "chat_rooms"
  add_foreign_key "chat_suspensions", "users"
  add_foreign_key "faction_subscription_grants", "factions"
  add_foreign_key "faction_subscription_grants", "users", column: "granted_by_id"
  add_foreign_key "member_activity_snapshots", "factions"
  add_foreign_key "personal_stat_snapshots", "users"
  add_foreign_key "personal_stat_snapshots", "users"
  add_foreign_key "ranked_war_attacks", "ranked_wars"
  add_foreign_key "ranked_wars", "factions"
  add_foreign_key "sessions", "users"
  add_foreign_key "spy_reports", "factions"
  add_foreign_key "subscription_grants", "faction_subscription_grants"
  add_foreign_key "subscription_grants", "users"
  add_foreign_key "users", "factions"
  add_foreign_key "xanax_payments", "users", column: "recipient_id"
  add_foreign_key "xanax_payments", "users", column: "sender_id"
end
