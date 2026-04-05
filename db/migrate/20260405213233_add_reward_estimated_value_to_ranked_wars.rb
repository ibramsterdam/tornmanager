class AddRewardEstimatedValueToRankedWars < ActiveRecord::Migration[8.1]
  def change
    add_column :ranked_wars, :reward_estimated_value, :integer, limit: 8
  end
end
