class AddEscapeAlertToEliminationSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :elimination_settings, :notify_escapes, :boolean, null: false, default: true
    add_column :elimination_settings, :escape_floor_tickets, :integer, null: false, default: 10
    add_column :elimination_settings, :escape_threshold_tickets, :integer, null: false, default: 50
  end
end
