class RemovePushRivalsFromEliminationSettings < ActiveRecord::Migration[8.0]
  def change
    remove_column :elimination_settings, :notify_push_rivals, :boolean, null: false, default: true
  end
end
