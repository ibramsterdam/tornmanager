class CreateCompanySnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :company_snapshots do |t|
      t.integer :company_torn_id, null: false
      t.date :date, null: false
      t.integer :company_type_id, null: false
      t.integer :rating, null: false, default: 0
      t.integer :employees_hired
      t.integer :employees_capacity
      t.bigint :daily_income
      t.integer :daily_customers
      t.bigint :weekly_income
      t.integer :weekly_customers
    end

    add_index :company_snapshots, [ :company_torn_id, :date ], unique: true
    add_index :company_snapshots, [ :company_type_id, :rating, :date ]
    add_index :company_snapshots, :date
  end
end
