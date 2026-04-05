namespace :db do
  namespace :seed do
    desc "Seed 14 days of activity snapshot data for development"
    task activities: :environment do
      load Rails.root.join("db/seeds/activities.rb")
    end
  end
end
