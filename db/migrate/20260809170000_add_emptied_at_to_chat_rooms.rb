class AddEmptiedAtToChatRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_rooms, :emptied_at, :datetime
    add_index :chat_rooms, :emptied_at
  end
end
