class AddNotificationTogglesToEliminationSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :elimination_settings, :notify_push_ours, :boolean, null: false, default: true
    add_column :elimination_settings, :notify_push_rivals, :boolean, null: false, default: true
    add_column :elimination_settings, :notify_countdown, :boolean, null: false, default: true
    add_column :elimination_settings, :notify_ticks, :boolean, null: false, default: true
    add_column :elimination_settings, :notify_eliminations, :boolean, null: false, default: true
    add_column :elimination_settings, :notify_standings, :boolean, null: false, default: true
    add_column :elimination_settings, :notify_health, :boolean, null: false, default: true
  end
end
