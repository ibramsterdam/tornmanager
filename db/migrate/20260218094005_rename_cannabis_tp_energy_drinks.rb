class RenameCannabisTpEnergyDrinks < ActiveRecord::Migration[8.1]
  def change
    rename_column :personal_stat_snapshots, :drugs_cannabis, :items_used_energy_drinks
  end
end
