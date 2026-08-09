class DropScriptVersions < ActiveRecord::Migration[8.1]
  def up
    drop_table :script_versions
  end

  def down
    create_table :script_versions do |t|
      t.text :changelog
      t.date :released_at, null: false
      t.text :script_content
      t.string :version, null: false
      t.timestamps
      t.index [ :version ], unique: true
    end
  end
end
