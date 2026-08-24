class AddSourceToApiCalls < ActiveRecord::Migration[8.1]
  def change
    add_column :api_calls, :source, :string
  end
end
