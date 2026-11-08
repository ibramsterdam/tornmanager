class CreateCompanyDaysAndNews < ActiveRecord::Migration[8.1]
  def change
    create_table :company_days do |t|
      t.integer :company_torn_id, null: false
      t.references :user, foreign_key: { on_delete: :nullify }
      t.date :date, null: false
      t.datetime :captured_at, null: false
      t.json :profile
      t.json :detailed
      t.json :employees
      t.json :stock
      t.timestamps
    end
    add_index :company_days, [ :company_torn_id, :date ], unique: true

    create_table :company_news_entries do |t|
      t.integer :company_torn_id, null: false
      t.string :news_id, null: false
      t.datetime :occurred_at, null: false
      t.text :text, null: false
      t.timestamps
    end
    add_index :company_news_entries, [ :company_torn_id, :news_id ], unique: true
    add_index :company_news_entries, [ :company_torn_id, :occurred_at ]
  end
end
