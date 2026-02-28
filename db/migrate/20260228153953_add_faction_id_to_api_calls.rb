class AddFactionIdToApiCalls < ActiveRecord::Migration[8.1]
  def change
    add_reference :api_calls, :faction, null: true, foreign_key: true
  end
end
