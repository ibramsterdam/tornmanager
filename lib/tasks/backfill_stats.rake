namespace :stats do
  desc "Backfill historical personal stats for 2026 (CORE STATS ONLY - fast)"
  task backfill_2026_core: :environment do
    # Core stats needed for faction page (only 7 attributes instead of 157)
    CORE_STAT_MAPPING = {
      "xantaken" => :drugs_xanax,
      "refills" => :other_refills_energy,
      "nerverefills" => :other_refills_nerve,
      "meritsbought" => :other_merits_bought,
      "boostersused" => :items_used_boosters,
      "missionscompleted" => :missions_missions,
      "timeplayed" => :other_activity_time
    }.freeze

    run_backfill(CORE_STAT_MAPPING, "CORE STATS (Faction Page)")
  end

  desc "Backfill historical personal stats for 2026 (ALL 157 ATTRIBUTES - slow)"
  task backfill_2026_full: :environment do
    # Complete stat name mapping from API to database columns (157 attributes)
    FULL_STAT_MAPPING = {
      # Attacking (36 attributes)
      "attackswon" => :attacking_attacks_won,
      "attackslost" => :attacking_attacks_lost,
      "attacksdraw" => :attacking_attacks_stalemate,
      "attacksassisted" => :attacking_attacks_assist,
      "defendswon" => :attacking_defends_won,
      "defendslost" => :attacking_defends_lost,
      "defendsstalemated" => :attacking_defends_stalemate,
      "elo" => :attacking_elo,
      "yourunaway" => :attacking_escapes_player,
      "theyrunaway" => :attacking_escapes_foes,
      "unarmoredwon" => :attacking_unarmored_wins,
      "bestkillstreak" => :attacking_killstreak_best,
      "attackhits" => :attacking_hits_success,
      "attackmisses" => :attacking_hits_miss,
      "attackdamage" => :attacking_damage_total,
      "bestdamage" => :attacking_damage_best,
      "onehitkills" => :attacking_hits_one_hit_kills,
      "attackcriticalhits" => :attacking_hits_critical,
      "roundsfired" => :attacking_ammunition_total,
      "specialammoused" => :attacking_ammunition_special,
      "hollowammoused" => :attacking_ammunition_hollow_point,
      "tracerammoused" => :attacking_ammunition_tracer,
      "piercingammoused" => :attacking_ammunition_piercing,
      "incendiaryammoused" => :attacking_ammunition_incendiary,
      "attacksstealthed" => :attacking_attacks_stealth,
      "retals" => :attacking_faction_retaliations,
      "moneymugged" => :attacking_networth_money_mugged,
      "largestmug" => :attacking_networth_largest_mug,
      "itemslooted" => :attacking_networth_items_looted,
      "highestbeaten" => :attacking_highest_level_beaten,
      "respectforfaction" => :attacking_faction_respect,
      "rankedwarhits" => :attacking_faction_ranked_war_hits,
      "raidhits" => :attacking_faction_raid_hits,
      "territoryjoins" => :attacking_faction_territory_wall_joins,
      "territoryclears" => :attacking_faction_territory_wall_clears,
      "territorytime" => :attacking_faction_territory_wall_time,

      # Jobs (2 attributes)
      "jobpointsused" => :jobs_job_points_used,
      "trainsreceived" => :jobs_trains_received,

      # Trading (11 attributes)
      "marketitemsbought" => :trading_items_bought_market,
      "cityitemsbought" => :trading_items_bought_shops,
      "auctionswon" => :trading_items_auctions_won,
      "auctionsells" => :trading_items_auctions_sold,
      "itemssent" => :trading_items_sent,
      "trades" => :trading_trades,
      "pointsbought" => :trading_points_bought,
      "pointssold" => :trading_points_sold,
      "bazaarcustomers" => :trading_bazaar_customers,
      "bazaarsales" => :trading_bazaar_sales,
      "bazaarprofit" => :trading_bazaar_profit,

      # Jail (5 attributes)
      "jailed" => :jail_times_jailed,
      "peoplebusted" => :jail_busts_success,
      "failedbusts" => :jail_busts_fails,
      "peoplebought" => :jail_bails_amount,
      "peopleboughtspent" => :jail_bails_fees,

      # Hospital (6 attributes)
      "hospital" => :hospital_times_hospitalized,
      "medicalitemsused" => :hospital_medical_items_used,
      "bloodwithdrawn" => :hospital_blood_withdrawn,
      "reviveskill" => :hospital_reviving_skill,
      "revives" => :hospital_reviving_revives,
      "revivesreceived" => :hospital_reviving_revives_received,

      # Finishing hits (12 attributes)
      "heavyhits" => :finishing_hits_heavy_artillery,
      "machinehits" => :finishing_hits_machine_guns,
      "riflehits" => :finishing_hits_rifles,
      "smghits" => :finishing_hits_sub_machine_guns,
      "shotgunhits" => :finishing_hits_shotguns,
      "pistolhits" => :finishing_hits_pistols,
      "temphits" => :finishing_hits_temporary,
      "piercinghits" => :finishing_hits_piercing,
      "slashinghits" => :finishing_hits_slashing,
      "clubbinghits" => :finishing_hits_clubbing,
      "mechanicalhits" => :finishing_hits_mechanical,
      "h2hhits" => :finishing_hits_hand_to_hand,

      # Communication (7 attributes)
      "mailssent" => :communication_mails_sent_total,
      "friendmailssent" => :communication_mails_sent_friends,
      "factionmailssent" => :communication_mails_sent_faction,
      "companymailssent" => :communication_mails_sent_colleagues,
      "spousemailssent" => :communication_mails_sent_spouse,
      "classifiedadsplaced" => :communication_classified_ads,
      "personalsplaced" => :communication_personals,

      # Crimes (10 attributes)
      "vandalism" => :crimes_offenses_vandalism,
      "fraud" => :crimes_offenses_fraud,
      "theft" => :crimes_offenses_theft,
      "counterfeiting" => :crimes_offenses_counterfeiting,
      "illicitservices" => :crimes_offenses_illicit_services,
      "cybercrime" => :crimes_offenses_cybercrime,
      "extortion" => :crimes_offenses_extortion,
      "illegalproduction" => :crimes_offenses_illegal_production,
      "organizedcrimes" => :crimes_offenses_organized_crimes,
      "criminaloffenses" => :crimes_offenses_total,

      # Bounties (6 attributes)
      "bountiesplaced" => :bounties_placed_amount,
      "totalbountyspent" => :bounties_placed_value,
      "bountiescollected" => :bounties_collected_amount,
      "totalbountyreward" => :bounties_collected_value,
      "bountiesreceived" => :bounties_received_amount,
      "receivedbountyvalue" => :bounties_received_value,

      # Items (13 attributes)
      "cityfinds" => :items_found_city,
      "dumpfinds" => :items_found_dump,
      "eastereggsfound" => :items_found_easter_eggs,
      "itemsdumped" => :items_trashed,
      "booksread" => :items_used_books,
      "boostersused" => :items_used_boosters,
      "consumablesused" => :items_used_consumables,
      "candyused" => :items_used_candy,
      "alcoholused" => :items_used_alcohol,
      "energydrinkused" => :items_used_energy_drinks,
      "statenhancersused" => :items_used_stat_enhancers,
      "eastereggsused" => :items_used_easter_eggs,
      "virusescoded" => :items_viruses_coded,

      # Travel (17 attributes)
      "traveltimes" => :travel_total,
      "timespenttraveling" => :travel_time_spent,
      "itemsboughtabroad" => :travel_items_bought,
      "huntingskill" => :travel_hunting_skill,
      "attackswonabroad" => :travel_attacks_won,
      "defendslostabroad" => :travel_defends_lost,
      "argtravel" => :travel_argentina,
      "cantravel" => :travel_canada,
      "caytravel" => :travel_cayman_islands,
      "chitravel" => :travel_china,
      "hawtravel" => :travel_hawaii,
      "japtravel" => :travel_japan,
      "mextravel" => :travel_mexico,
      "uaetravel" => :travel_united_arab_emirates,
      "uktravel" => :travel_united_kingdom,
      "satravel" => :travel_south_africa,
      "switravel" => :travel_switzerland,

      # Drugs (14 attributes)
      "cantaken" => :drugs_cannabis,
      "exttaken" => :drugs_ecstasy,
      "kettaken" => :drugs_ketamine,
      "lsdtaken" => :drugs_lsd,
      "opitaken" => :drugs_opium,
      "pcptaken" => :drugs_pcp,
      "shrtaken" => :drugs_shrooms,
      "spetaken" => :drugs_speed,
      "victaken" => :drugs_vicodin,
      "xantaken" => :drugs_xanax,
      "drugsused" => :drugs_total,
      "overdosed" => :drugs_overdoses,
      "rehabs" => :drugs_rehabilitations_amount,
      "rehabcost" => :drugs_rehabilitations_fees,

      # Missions (4 attributes)
      "missionscompleted" => :missions_missions,
      "contractscompleted" => :missions_contracts_total,
      "dukecontractscompleted" => :missions_contracts_duke,
      "missioncreditsearned" => :missions_credits,

      # Racing (4 attributes)
      "racingskill" => :racing_skill,
      "racingpointsearned" => :racing_points,
      "racesentered" => :racing_races_entered,
      "raceswon" => :racing_races_won,

      # Networth (1 attribute)
      "networth" => :networth_total,

      # Other (2 attributes)
      "activestreak" => :other_activity_streak_current,
      "bestactivestreak" => :other_activity_streak_best,
      "awards" => :other_awards,
      "tokenrefills" => :other_refills_token,
      "daysbeendonator" => :other_donator_days
    }.freeze

    run_backfill(FULL_STAT_MAPPING, "ALL STATS (Complete)")
  end

  desc "Dry run of core stats backfill"
  task backfill_2026_core_dry_run: :environment do
    dry_run_backfill(7, "CORE")
  end

  desc "Dry run of full stats backfill"
  task backfill_2026_full_dry_run: :environment do
    dry_run_backfill(157, "FULL")
  end

  private

  def dry_run_backfill(stat_count, mode)
    start_date = Date.new(2026, 1, 1)
    end_date = Date.new(2026, 1, 20)
    dates = (start_date..end_date).to_a

    factions = Faction.where(track_stats: true)

    puts "=" * 80
    puts "🔍 BACKFILL DRY RUN - #{mode} MODE"
    puts "=" * 80
    puts
    puts "This would backfill stats for:"
    puts

    total_users = 0
    total_snapshots_needed = 0
    total_snapshots_existing = 0

    factions.each do |faction|
      puts "🏢 #{faction.name}"

      faction.users.find_each do |user|
        total_users += 1

        dates.each do |date|
          existing = user.personal_stat_snapshots.where(date: date).first

          if existing
            total_snapshots_existing += 1
          else
            total_snapshots_needed += 1
          end
        end
      end
    end

    puts
    puts "📊 Summary:"
    puts "   - Total users: #{total_users}"
    puts "   - Date range: #{start_date} to #{end_date} (#{dates.size} days)"
    puts "   - Snapshots already existing: #{total_snapshots_existing}"
    puts "   - Snapshots to create: #{total_snapshots_needed}"
    puts "   - API calls required: #{total_snapshots_needed * stat_count} (#{stat_count} stats per snapshot)"
    puts "   - Estimated time: ~#{(total_snapshots_needed * stat_count * 0.3 / 60).round(1)} minutes"
    puts
    if mode == "CORE"
      puts "To run the actual backfill, use: rails stats:backfill_2026_core"
      puts "For complete backfill (all 157 stats): rails stats:backfill_2026_full"
    else
      puts "To run the actual backfill, use: rails stats:backfill_2026_full"
      puts "For faster backfill (7 core stats only): rails stats:backfill_2026_core"
    end
    puts
  end

  def run_backfill(stat_mapping, mode)
    require "net/http"
    require "json"

    api_key = OwnerCredentials.api_key

    if api_key.blank?
      puts "❌ No API key found in OwnerCredentials"
      exit 1
    end

    factions = Faction.where(track_stats: true)

    if factions.empty?
      puts "❌ No factions with tracking enabled"
      exit 1
    end

    start_date = Date.new(2026, 1, 1)
    end_date = Date.new(2026, 1, 20)
    dates = (start_date..end_date).to_a

    puts "=" * 80
    puts "🔄 BACKFILL PERSONAL STATS - #{mode}"
    puts "=" * 80
    puts
    puts "📅 Date range: #{start_date} to #{end_date} (#{dates.size} days)"
    puts "📊 Factions: #{factions.map(&:name).join(', ')}"
    puts "👥 Total users: #{factions.sum { |f| f.users.count }}"
    puts "📈 Attributes per snapshot: #{stat_mapping.size}"
    puts
    puts "⏱️  Estimated time: ~#{(factions.sum { |f| f.users.count } * dates.size * stat_mapping.size * 0.3 / 60).round(1)} minutes"
    puts
    puts "=" * 80
    puts

    total_snapshots_created = 0
    total_snapshots_skipped = 0
    total_errors = 0

    factions.each do |faction|
      puts "🏢 Processing faction: #{faction.name}"
      puts

      faction.users.find_each do |user|
        user_snapshots_created = 0
        user_snapshots_skipped = 0

        print "  👤 #{user.name.ljust(30)} (#{user.torn_id.to_s.ljust(8)})"

        dates.each do |date|
          existing = user.personal_stat_snapshots.where(date: date).first

          if existing
            user_snapshots_skipped += 1
            next
          end

          timestamp = date.to_time.to_i
          snapshot_data = {}
          failed_stats = []

          stat_mapping.each do |api_stat_name, db_column|
            begin
              uri = URI("https://api.torn.com/v2/user/#{user.torn_id}/personalstats?stat=#{api_stat_name}&timestamp=#{timestamp}&comment=tmanager")
              http = Net::HTTP.new(uri.host, uri.port)
              http.use_ssl = true
              http.read_timeout = 10
              http.open_timeout = 5

              request = Net::HTTP::Get.new(uri)
              request["Authorization"] = "ApiKey #{api_key}"

              response = http.request(request)
              data = JSON.parse(response.body)

              if data["error"]
                failed_stats << api_stat_name
                break
              end

              if data["personalstats"]&.any?
                value = data["personalstats"].first["value"]
                snapshot_data[db_column] = value
              end

              sleep(0.3)
            rescue => e
              failed_stats << "#{api_stat_name} (#{e.message})"
              break
            end
          end

          if snapshot_data.size == stat_mapping.size
            snapshot = user.personal_stat_snapshots.build(snapshot_data)
            snapshot.date = date
            snapshot.created_at = date.to_time.midday

            if snapshot.save
              user_snapshots_created += 1
            else
              total_errors += 1
              print "\n     ❌ #{date}: Failed to save: #{snapshot.errors.full_messages.join(', ')}\n"
            end
          else
            if failed_stats.any?
              total_errors += 1
              print "\n     ⚠️  Skipping user - API error on #{date}: #{failed_stats.first}\n"
              break
            end
          end
        end

        total_snapshots_created += user_snapshots_created
        total_snapshots_skipped += user_snapshots_skipped

        if user_snapshots_created > 0
          print " ✅ #{user_snapshots_created}"
        end
        if user_snapshots_skipped > 0
          print " ⏭️  #{user_snapshots_skipped}"
        end
        puts
      end

      puts
    end

    puts "=" * 80
    puts "✅ BACKFILL COMPLETE!"
    puts "=" * 80
    puts
    puts "📊 Summary:"
    puts "   - Snapshots created: #{total_snapshots_created}"
    puts "   - Snapshots skipped: #{total_snapshots_skipped}"
    puts "   - Errors: #{total_errors}"
    puts
  end
end
