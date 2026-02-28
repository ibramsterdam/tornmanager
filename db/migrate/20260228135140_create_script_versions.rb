class CreateScriptVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :script_versions do |t|
      t.string :version, null: false
      t.text :changelog
      t.date :released_at, null: false

      t.timestamps
    end

    add_index :script_versions, :version, unique: true
  end
end
