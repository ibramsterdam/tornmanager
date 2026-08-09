class AddEncryptedToChatRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_rooms, :encrypted, :boolean, null: false, default: false
  end
end
