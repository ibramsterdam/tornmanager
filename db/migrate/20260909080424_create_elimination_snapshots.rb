class CreateEliminationSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :elimination_snapshots do |t|
      t.integer :team_torn_id, null: false
      t.string :name, null: false
      t.integer :tickets, null: false
      t.integer :lives, null: false
      t.integer :wins, null: false
      t.integer :losses, null: false
      t.integer :position
      t.boolean :eliminated, null: false, default: false
      t.datetime :captured_at, null: false

      t.timestamps
    end

    add_index :elimination_snapshots, [ :team_torn_id, :captured_at ]
    add_index :elimination_snapshots, :captured_at
  end
end
