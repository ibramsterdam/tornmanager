class CreateEliminationSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :elimination_settings do |t|
      t.string :team_name, null: false, default: "Conspiracy Theorists"
      t.string :api_key
      t.string :alerts_webhook_url
      t.string :standings_webhook_url
      t.string :role_id
      t.boolean :polling_active, null: false, default: false
      t.integer :poll_interval_seconds, null: false, default: 2
      t.integer :push_window_seconds, null: false, default: 10
      t.integer :push_ticket_threshold, null: false, default: 10
      t.integer :push_resolve_seconds, null: false, default: 180
      t.integer :countdown_bottom_ranks, null: false, default: 2
      t.integer :standings_interval_minutes, null: false, default: 60
      t.datetime :life_ticks_from, null: false, default: Time.utc(2026, 9, 11, 12)
      t.datetime :last_polled_at
      t.string :last_error

      t.timestamps
    end
  end
end
