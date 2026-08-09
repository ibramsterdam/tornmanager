class AddPublicRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_rooms, :kind, :string, null: false, default: "private"
    add_index :chat_rooms, :kind

    add_column :chat_memberships, :anon_name, :string

    # Public rooms are permanent fixtures with no single owner.
    change_column_null :chat_rooms, :host_user_id, true

    up_only do
      ChatRoom.reset_column_information
      ChatRoom.create!(name: "The Lounge", kind: "public", host_user_id: nil, last_message_at: Time.current)
    end
  end
end
