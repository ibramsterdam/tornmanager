class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.integer :torn_id, null: false, index: { unique: true }
      t.string :name
      t.integer :company_type_id, null: false
      t.integer :rating, null: false, default: 0
      t.integer :employees_hired
      t.datetime :synced_at
      t.timestamps
      t.index [ :company_type_id, :rating ]
    end
  end
end
