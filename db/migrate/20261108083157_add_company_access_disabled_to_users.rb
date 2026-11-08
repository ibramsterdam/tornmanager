class AddCompanyAccessDisabledToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :company_access_disabled, :boolean, default: false, null: false
  end
end
