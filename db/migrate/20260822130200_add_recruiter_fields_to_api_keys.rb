class AddRecruiterFieldsToApiKeys < ActiveRecord::Migration[8.1]
  def change
    add_column :api_keys, :recruiter_fetch_allowed, :boolean, null: false, default: false
    add_column :api_keys, :submitted_by_id, :integer
  end
end
