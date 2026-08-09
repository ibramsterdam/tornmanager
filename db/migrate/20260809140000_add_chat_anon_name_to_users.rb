class AddChatAnonNameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :chat_anon_name, :string
    add_index :users, :chat_anon_name, unique: true

    # Anonymity is now a single forever-name per user (see users.chat_anon_name),
    # so the per-membership copy is redundant.
    remove_column :chat_memberships, :anon_name, :string
  end
end
