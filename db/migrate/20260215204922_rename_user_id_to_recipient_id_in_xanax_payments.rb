class RenameUserIdToRecipientIdInXanaxPayments < ActiveRecord::Migration[8.1]
  def change
    rename_column :xanax_payments, :user_id, :recipient_id
  end
end
