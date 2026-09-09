class ChangePushResolveDefaultOnEliminationSettings < ActiveRecord::Migration[8.0]
  def change
    change_column_default :elimination_settings, :push_resolve_seconds, from: 180, to: 900

    reversible do |direction|
      direction.up { execute "UPDATE elimination_settings SET push_resolve_seconds = 900 WHERE push_resolve_seconds = 180" }
      direction.down { execute "UPDATE elimination_settings SET push_resolve_seconds = 180 WHERE push_resolve_seconds = 900" }
    end
  end
end
