class FixArmoryNewsEntryActions < ActiveRecord::Migration[8.1]
  def up
    ArmoryNewsEntry.where(action: "unknown").find_each do |entry|
      plain = entry.text.gsub(/<[^>]+>/, "").strip
      name = entry.player_name.to_s
      after_name = plain.sub(/\A#{Regexp.escape(name)}\s*/, "")

      new_action, new_item = case after_name
      when /\Agave (\d+)x (.+?) to/
        [ "loaned", $2 ]
      when /\Aretrieved (\d+)x (.+?) from/
        [ "returned", $2 ]
      when /\Adeposited (\d+)\s*x (.+)/
        [ "deposited", $2 ]
      when /\Afilled one of the faction's (.+?) items/
        [ "filled", $1 ]
      end

      entry.update_columns(action: new_action, item: new_item) if new_action
    end
  end

  def down
  end
end
