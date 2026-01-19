class CreateTornUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :torn_users do |t|
      t.string  :name,    null: false
      t.integer :torn_id, null: false
      t.integer :level,   null: false
      t.string  :gender,  null: false

      t.references :user, foreign_key: true, null: true

      t.timestamps
    end

    add_index :torn_users, :torn_id, unique: true
  end
end
