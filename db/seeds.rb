  require "yaml"
unless Rails.env.development?
  puts "WARN: Seeding is just for development!"
else
  print "Starting Seed…\n"
  bram = User.find_or_create_by!(torn_id: 2728237) do |user|
    user.name = "Bram"
    user.gender = "Male"
    user.level = 69
    user.api_key = Rails.application.credentials.dig(:bram, :api_key)
  end

  print "Finished!"
end
