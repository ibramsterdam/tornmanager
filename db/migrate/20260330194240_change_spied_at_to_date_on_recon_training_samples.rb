class ChangeSpiedAtToDateOnReconTrainingSamples < ActiveRecord::Migration[8.1]
  def change
    change_column :recon_training_samples, :spied_at, :date, null: false
    add_index :recon_training_samples, [ :player_id, :spied_at ], unique: true
  end
end
