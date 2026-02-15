class CreateApiCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :api_calls do |t|
      t.references :user, null: false, foreign_key: true
      t.string :api_key, null: false
      t.string :endpoint, null: false
      t.string :selections
      t.integer :response_time
      t.string :status, null: false
      t.text :error_message
      t.integer :torn_api_timestamp

      t.timestamps
    end

    add_index :api_calls, :created_at
    add_index :api_calls, [ :user_id, :created_at ]
  end
end
