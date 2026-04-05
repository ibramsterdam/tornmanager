return puts "WARN: Seeding is just for development!" unless Rails.env.development?

print "Seeding activity snapshots..."
user = User.find_by(torn_id: 2728237)

unless user&.faction
  puts " skipped (no faction)."
  return
end

faction = user.faction
members = faction.users.active

unless members.any?
  puts " skipped (no faction members)."
  return
end

MemberActivitySnapshot.where(faction_id: faction.id).delete_all

hourly_pct = [
  0.25, 0.15, 0.10, 0.05, 0.03, 0.03, 0.05, 0.10,
  0.15, 0.25, 0.35, 0.45, 0.50, 0.55, 0.60, 0.65,
  0.70, 0.80, 0.90, 0.95, 0.90, 0.80, 0.65, 0.40
]
day_multiplier = { 0 => 1.1, 1 => 0.95, 2 => 0.95, 3 => 1.0, 4 => 1.0, 5 => 1.05, 6 => 1.15 }

snapshots = []
(0..13).each do |days_ago|
  date = Date.current - days_ago
  (0..23).each do |hour|
    next if days_ago == 0 && hour > Time.current.hour

    recorded_at = date.in_time_zone("UTC").change(hour: hour)
    4.times do |quarter|
      poll_time = recorded_at + (quarter * 15).minutes

      members.each do |member|
        offset = (member.torn_id * 3) % 6 - 3
        shifted_pct = hourly_pct[(hour - offset) % 24] * day_multiplier[date.wday]
        roll = ((member.torn_id * 17 + hour * 13 + days_ago * 7 + quarter * 3) % 100) / 100.0

        status = if roll < shifted_pct * 0.7
                   "Online"
                 elsif roll < shifted_pct
                   "Idle"
                 else
                   "Offline"
                 end

        snapshots << {
          faction_id: faction.id,
          torn_member_id: member.torn_id,
          member_name: member.name,
          recorded_at: poll_time,
          hour_utc: hour,
          day_of_week: date.wday,
          status: status,
          created_at: poll_time,
          updated_at: poll_time
        }
      end
    end
  end
end

MemberActivitySnapshot.insert_all(snapshots)
puts " #{snapshots.size} snapshots for #{members.size} members."
