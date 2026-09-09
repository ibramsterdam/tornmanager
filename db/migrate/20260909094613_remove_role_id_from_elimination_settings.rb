class RemoveRoleIdFromEliminationSettings < ActiveRecord::Migration[8.0]
  def change
    remove_column :elimination_settings, :role_id, :string
  end
end
