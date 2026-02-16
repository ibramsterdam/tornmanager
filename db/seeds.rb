  require "yaml"
unless Rails.env.development?
  puts "WARN: Seeding is just for development!"
else
  print "Starting Seed…\n"
  bram = User.find_or_create_by!(torn_id: 2728237) do |user|
    user.name = "Bram"
    user.level = 69
    user.api_key = OwnerCredentials.api_key
  end

  print "Finished!"
end
