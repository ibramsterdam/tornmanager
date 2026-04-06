unless Rails.env.development?
  puts "WARN: Seeding is just for development!"
else
  print "Starting Seed...\n"

  # Stocks
  stocks = [
    { torn_id: 1,  acronym: "TSB", name: "Torn & Shanghai Banking",  current_price: 1164.92, dividend_frequency: 31, dividend_requirement: 3_000_000, dividend_description: "$50,000,000" },
    { torn_id: 2,  acronym: "TCI", name: "Torn City Investments",    current_price: 1192.33, dividend_frequency: 7,  dividend_requirement: 1_500_000, dividend_description: "a 10% bank interest bonus" },
    { torn_id: 3,  acronym: "SYS", name: "Syscore MFG",              current_price: 698.81,  dividend_frequency: 7,  dividend_requirement: 3_000_000, dividend_description: "an Advanced firewall" },
    { torn_id: 4,  acronym: "LAG", name: "Legal Authorities Group",   current_price: 466.03,  dividend_frequency: 7,  dividend_requirement: 750_000,   dividend_description: "1x Lawyer's Business Card" },
    { torn_id: 5,  acronym: "IOU", name: "Insured On Us",            current_price: 177.84,  dividend_frequency: 31, dividend_requirement: 3_000_000, dividend_description: "$12,000,000" },
    { torn_id: 6,  acronym: "GRN", name: "Grain",                    current_price: 310.14,  dividend_frequency: 31, dividend_requirement: 500_000,   dividend_description: "$4,000,000" },
    { torn_id: 7,  acronym: "THS", name: "Torn City Health Service",  current_price: 388.09,  dividend_frequency: 7,  dividend_requirement: 150_000,   dividend_description: "1x Box of Medical Supplies" },
    { torn_id: 8,  acronym: "YAZ", name: "Yazoo",                    current_price: 53.31,   dividend_frequency: 7,  dividend_requirement: 1_000_000, dividend_description: "Free banner advertising" },
    { torn_id: 9,  acronym: "TCT", name: "The Torn City Times",      current_price: 317.68,  dividend_frequency: 31, dividend_requirement: 100_000,   dividend_description: "$1,000,000" },
    { torn_id: 10, acronym: "CNC", name: "Crude & Co",               current_price: 872.94,  dividend_frequency: 31, dividend_requirement: 7_500_000, dividend_description: "$80,000,000" },
    { torn_id: 11, acronym: "MSG", name: "Messaging Inc.",            current_price: 282.44,  dividend_frequency: 7,  dividend_requirement: 300_000,   dividend_description: "Free classified advertising" },
    { torn_id: 12, acronym: "TMI", name: "TC Music Industries",      current_price: 232.80,  dividend_frequency: 31, dividend_requirement: 6_000_000, dividend_description: "$25,000,000" },
    { torn_id: 13, acronym: "TCP", name: "TC Media Productions",     current_price: 522.36,  dividend_frequency: 7,  dividend_requirement: 1_000_000, dividend_description: "a Company sales boost" },
    { torn_id: 14, acronym: "IIL", name: "I Industries Ltd.",        current_price: 134.39,  dividend_frequency: 7,  dividend_requirement: 1_000_000, dividend_description: "50% coding time reduction" },
    { torn_id: 15, acronym: "FHG", name: "Feathery Hotels Group",    current_price: 850.04,  dividend_frequency: 7,  dividend_requirement: 2_000_000, dividend_description: "1x Feathery Hotel Coupon" },
    { torn_id: 16, acronym: "SYM", name: "Symbiotic Ltd.",           current_price: 708.34,  dividend_frequency: 7,  dividend_requirement: 500_000,   dividend_description: "1x Drug Pack" },
    { torn_id: 17, acronym: "LSC", name: "Lucky Shot Casino",        current_price: 562.53,  dividend_frequency: 7,  dividend_requirement: 500_000,   dividend_description: "1x Lottery Voucher" },
    { torn_id: 18, acronym: "PRN", name: "Performance Ribaldry",     current_price: 619.75,  dividend_frequency: 7,  dividend_requirement: 1_000_000, dividend_description: "1x Erotic DVD" },
    { torn_id: 19, acronym: "EWM", name: "Eaglewood Mercenary",      current_price: 285.56,  dividend_frequency: 7,  dividend_requirement: 1_000_000, dividend_description: "1x Box of Grenades" },
    { torn_id: 20, acronym: "TCM", name: "Torn City Motors",         current_price: 300.44,  dividend_frequency: 7,  dividend_requirement: 1_000_000, dividend_description: "10% racing skill gain boost" },
    { torn_id: 21, acronym: "ELT", name: "Empty Lunchbox Traders",   current_price: 311.85,  dividend_frequency: 7,  dividend_requirement: 5_000_000, dividend_description: "10% home upgrade discount" },
    { torn_id: 22, acronym: "HRG", name: "Home Retail Group",        current_price: 270.35,  dividend_frequency: 31, dividend_requirement: 10_000_000, dividend_description: "1x Random Property" },
    { torn_id: 23, acronym: "TGP", name: "Tell Group Plc.",          current_price: 146.56,  dividend_frequency: 7,  dividend_requirement: 2_500_000, dividend_description: "a Company advertising boost" },
    { torn_id: 24, acronym: "MUN", name: "Munster Beverage Corp.",   current_price: 557.89,  dividend_frequency: 7,  dividend_requirement: 5_000_000, dividend_description: "1x Six-Pack of Energy Drink" },
    { torn_id: 25, acronym: "WSU", name: "West Side University",     current_price: 110.01,  dividend_frequency: 7,  dividend_requirement: 1_000_000, dividend_description: "a 10% education course time reduction" },
    { torn_id: 26, acronym: "IST", name: "International School TC",  current_price: 517.55,  dividend_frequency: 7,  dividend_requirement: 100_000,   dividend_description: "Free education courses" },
    { torn_id: 27, acronym: "BAG", name: "Big Al's Gun Shop",        current_price: 488.85,  dividend_frequency: 7,  dividend_requirement: 3_000_000, dividend_description: "1x Ammunition Pack" },
    { torn_id: 28, acronym: "EVL", name: "Evil Ducks Candy Corp",    current_price: 645.12,  dividend_frequency: 7,  dividend_requirement: 100_000,   dividend_description: "1000 happiness" },
    { torn_id: 29, acronym: "MCS", name: "Mc Smoogle Corp",          current_price: 808.11,  dividend_frequency: 7,  dividend_requirement: 350_000,   dividend_description: "100 energy" },
    { torn_id: 30, acronym: "WLT", name: "Wind Lines Travel",        current_price: 797.11,  dividend_frequency: 7,  dividend_requirement: 9_000_000, dividend_description: "Private jet access" },
    { torn_id: 31, acronym: "TCC", name: "Torn City Clothing",       current_price: 506.24,  dividend_frequency: 31, dividend_requirement: 7_500_000, dividend_description: "1x Clothing Cache" },
    { torn_id: 32, acronym: "ASS", name: "Alcoholics Synonymous",    current_price: 349.34,  dividend_frequency: 7,  dividend_requirement: 1_000_000, dividend_description: "1x Six-Pack of Alcohol" },
    { torn_id: 33, acronym: "CBD", name: "Herbal Releaf Co.",        current_price: 410.23,  dividend_frequency: 7,  dividend_requirement: 350_000,   dividend_description: "50 nerve" },
    { torn_id: 34, acronym: "LOS", name: "Lo Squalo Waste",          current_price: 109.26,  dividend_frequency: 7,  dividend_requirement: 7_500_000, dividend_description: "25% boost to mission credits and money earned" },
    { torn_id: 35, acronym: "PTS", name: "PointLess",                current_price: 75.80,   dividend_frequency: 7,  dividend_requirement: 10_000_000, dividend_description: "100 points" }
  ]

  print "  Seeding #{stocks.size} stocks..."
  stocks.each do |attrs|
    Torn::Stock.find_or_initialize_by(torn_id: attrs[:torn_id]).update!(attrs)
  end
  puts " done."

  # Dev user
  print "  Seeding dev user..."
  user = User.find_or_create_by!(torn_id: 2728237) do |u|
    u.name = "Bram"
    u.level = 69
  end
  user.set_api_key!(AdminCredentials.api_key, "Limited Access") unless user.api_key.present?
  puts " done."

  print "Finished!\n"
end
