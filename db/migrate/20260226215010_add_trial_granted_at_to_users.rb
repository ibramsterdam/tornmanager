class AddTrialGrantedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :trial_granted_at, :datetime
  end
end
