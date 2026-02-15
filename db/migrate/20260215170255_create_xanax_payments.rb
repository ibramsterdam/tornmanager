class CreateXanaxPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :xanax_payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.string :log_id, null: false
      t.integer :xanax_amount, null: false
      t.integer :weeks_granted, null: false
      t.datetime :processed_at, null: false

      t.timestamps
    end

    add_index :xanax_payments, :log_id, unique: true
  end
end
