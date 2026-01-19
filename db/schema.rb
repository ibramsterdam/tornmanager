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

ActiveRecord::Schema[8.1].define(version: 2026_01_19_194955) do
  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
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

  create_table "torn_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "gender", null: false
    t.integer "level", null: false
    t.string "name", null: false
    t.integer "torn_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["torn_id"], name: "index_torn_users_on_torn_id", unique: true
    t.index ["user_id"], name: "index_torn_users_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.integer "torn_user_id"
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["torn_user_id"], name: "index_users_on_torn_user_id"
  end

  add_foreign_key "sessions", "users"
  add_foreign_key "torn_users", "users"
  add_foreign_key "users", "torn_users"
end
