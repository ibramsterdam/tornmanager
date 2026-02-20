class CreateRoadmapItems < ActiveRecord::Migration[8.1]
  def change
    create_table :roadmap_items do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "planned"
      t.string :category, null: false, default: "factions"
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :roadmap_items, [ :status, :position ]
  end
end
