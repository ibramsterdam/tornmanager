class AddAnonymousToChatRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_rooms, :anonymous, :boolean, null: false, default: false

    up_only do
      ChatRoom.reset_column_information

      lounge = ChatRoom.public_rooms.where(name: "The Lounge").first_or_create! do |room|
        room.last_message_at = Time.current
      end
      lounge.update!(anonymous: false)
      lounge.post_system_message("The Lounge now shows real names. For anonymous chat, join The Muggers Den.")

      den = ChatRoom.public_rooms.where(name: "The Muggers Den").first_or_create! do |room|
        room.last_message_at = Time.current
      end
      den.update!(anonymous: true)
    end
  end
end
