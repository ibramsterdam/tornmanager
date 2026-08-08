class CreateChatRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_rooms do |t|
      t.string :name, null: false
      t.string :invite_token, null: false, index: { unique: true }
      t.references :host_user, null: false, foreign_key: { to_table: :users }
      t.datetime :last_message_at, null: false
      t.timestamps
    end

    create_table :chat_memberships do |t|
      t.references :chat_room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :host, null: false, default: false
      t.timestamps
    end
    add_index :chat_memberships, [ :chat_room_id, :user_id ], unique: true

    create_table :chat_messages do |t|
      t.references :chat_room, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :body, null: false
      t.string :sender_name
      t.integer :sender_torn_id
      t.boolean :system, null: false, default: false
      t.timestamps
    end
  end
end
