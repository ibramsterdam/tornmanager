class AddScriptContentToScriptVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :script_versions, :script_content, :text
  end
end
