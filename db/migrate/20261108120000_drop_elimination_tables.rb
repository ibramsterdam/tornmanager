class DropEliminationTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :elimination_snapshots
    drop_table :elimination_settings
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
