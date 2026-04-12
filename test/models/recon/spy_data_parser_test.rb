require "test_helper"

class Recon::SpyDataParserTest < ActiveSupport::TestCase
  # -- Format 1: TornStats faction spy (with Faction + FF columns) --

  test "format 1: parses a single row" do
    input = "Trole [1485341]	78	None	5,751,694,281	7,905,360,376	4,692,172,959	297,478,845	18,646,706,461	3.00	24/03/26"

    results = Recon::SpyDataParser.parse(input)
    assert_equal 1, results.size

    row = results.first
    assert_equal 1485341, row.player_id
    assert_equal "Trole", row.name
    assert_equal 78, row.level
    assert_equal 5_751_694_281, row.strength
    assert_equal 7_905_360_376, row.defense
    assert_equal 4_692_172_959, row.speed
    assert_equal 297_478_845, row.dexterity
    assert_equal Date.new(2026, 3, 24), row.spied_at
  end

  test "format 1: parses multiple rows" do
    input = <<~TSV
      Trole [1485341]	78	None	5,751,694,281	7,905,360,376	4,692,172,959	297,478,845	18,646,706,461	3.00	24/03/26
      nV_Wulf [3570129]	24	NS Bomb Shelter	36,414	44,938	44,638	44,400	170,390	1.05	25/03/26
    TSV

    results = Recon::SpyDataParser.parse(input)
    assert_equal 2, results.size
  end

  test "format 1: strips commas from stat numbers" do
    input = "Dark [222379]	50	None	4,112,090,853	3,868,907,313	2,013,554,995	2,001,634,998	11,996,188,159	3.00	24/03/26"

    row = Recon::SpyDataParser.parse(input).first
    assert_equal 4_112_090_853, row.strength
    assert_equal 3_868_907_313, row.defense
  end

  test "format 1: extracts player_id from brackets" do
    input = "HT-Supermikk [108922]	100	|HT|	266,842,779,942	3,001,657,398	11,996,538,060	139,528,339,154	421,369,314,554	3.00	24/03/26"

    row = Recon::SpyDataParser.parse(input).first
    assert_equal 108922, row.player_id
    assert_equal "HT-Supermikk", row.name
  end

  test "format 1: skips header row" do
    input = <<~TSV
      Name	Level	Faction	Strength	Defense	Speed	Dexterity	Total	FF Bonus	Last Update
      Trole [1485341]	78	None	5,751,694,281	7,905,360,376	4,692,172,959	297,478,845	18,646,706,461	3.00	24/03/26
    TSV

    results = Recon::SpyDataParser.parse(input)
    assert_equal 1, results.size
  end

  # -- Format 2: Ranked spy list (with rank prefix, no Faction/FF columns) --

  test "format 2: parses row with rank prefix" do
    input = "107 cavpaca [2274053]	100	9,219,873,411	2,524,103,754	3,513,022,223	5,389,043,323	20,646,042,711	27/03/26	4 minutes ago	278,941"

    results = Recon::SpyDataParser.parse(input)
    assert_equal 1, results.size

    row = results.first
    assert_equal 2274053, row.player_id
    assert_equal "cavpaca", row.name
    assert_equal 100, row.level
    assert_equal 9_219_873_411, row.strength
    assert_equal 2_524_103_754, row.defense
    assert_equal 3_513_022_223, row.speed
    assert_equal 5_389_043_323, row.dexterity
    assert_equal Date.new(2026, 3, 27), row.spied_at
  end

  test "format 2: skips rows with N/A stats" do
    input = "109 HavokGDI [133687]	100	N/A	N/A	N/A	N/A	N/A	N/A	7 minutes ago	N/A"

    results = Recon::SpyDataParser.parse(input)
    assert_equal 0, results.size
  end

  test "format 2: skips rows with Unknown level" do
    input = "106 Lith [2137694]	Unknown	1,405,520,546	1,160,202,096	1,448,837,042	8,373,742,499	12,388,302,183	27/03/26	Unknown	201,124"

    results = Recon::SpyDataParser.parse(input)
    row = results.first
    assert_equal 2137694, row.player_id
    assert_nil row.level
  end

  test "format 2: skips header row" do
    input = <<~TSV
      Name	Level	Strength	Defense	Speed	Dexterity	Total	Last Updated	Last Action	Score
      107 cavpaca [2274053]	100	9,219,873,411	2,524,103,754	3,513,022,223	5,389,043,323	20,646,042,711	27/03/26	4 minutes ago	278,941
    TSV

    results = Recon::SpyDataParser.parse(input)
    assert_equal 1, results.size
  end

  test "format 2: parses row with rank as separate tab column" do
    input = "1\tPenicillin [1517799]\t100\t655,000,300,610,300\t2,761,464,594,401,500\t8,940,446,370,100\t12,344,518,438\t3,425,417,685,900,338\t30/03/26\t16 minutes ago\t81,243,777"

    results = Recon::SpyDataParser.parse(input)
    assert_equal 1, results.size

    row = results.first
    assert_equal 1517799, row.player_id
    assert_equal "Penicillin", row.name
    assert_equal 655_000_300_610_300, row.strength
    assert_equal Date.new(2026, 3, 30), row.spied_at
  end

  test "format 2: skips N/A rows with rank as separate tab column" do
    input = "18\tYaamean [2779971]\t100\tN/A\tN/A\tN/A\tN/A\tN/A\tN/A\t54 minutes ago\tN/A"

    results = Recon::SpyDataParser.parse(input)
    assert_equal 0, results.size
  end

  test "format 2: skips average row" do
    input = "Average:	20,155,271,658,445	59,122,116,213,084	5,655,748,625,209	5,554,996,840	84,938,691,493,578"

    results = Recon::SpyDataParser.parse(input)
    assert_equal 0, results.size
  end

  test "format 1: handles numeric faction name" do
    input = "Missbhavin [2382460]\t61\t300\t1,416,721\t1,646,694\t2,100,183\t1,409,042\t6,572,640\t1.29\t03/12/24"

    results = Recon::SpyDataParser.parse(input)
    assert_equal 1, results.size

    row = results.first
    assert_equal 2382460, row.player_id
    assert_equal 1_416_721, row.strength
    assert_equal Date.new(2024, 12, 3), row.spied_at
  end

  # -- Shared behavior --

  test "parses date in DD/MM/YY format" do
    input = "Test [123]	50	None	100	200	300	400	1000	1.00	01/01/26"

    row = Recon::SpyDataParser.parse(input).first
    assert_equal Date.new(2026, 1, 1), row.spied_at
  end

  test "skips blank lines" do
    input = <<~TSV
      Trole [1485341]	78	None	5,751,694,281	7,905,360,376	4,692,172,959	297,478,845	18,646,706,461	3.00	24/03/26

      Dark [222379]	50	None	4,112,090,853	3,868,907,313	2,013,554,995	2,001,634,998	11,996,188,159	3.00	24/03/26
    TSV

    results = Recon::SpyDataParser.parse(input)
    assert_equal 2, results.size
  end

  test "returns empty array for empty input" do
    assert_equal [], Recon::SpyDataParser.parse("")
    assert_equal [], Recon::SpyDataParser.parse(nil)
  end

  # -- JSONL format --

  test "jsonl: parses a single line" do
    input = '{"Name": "Alice [111]", "Level": "100", "Faction": "Test", "Strength": "1,000", "Defense": "2,000", "Speed": "500", "Dexterity": "300", "Total": "3,800", "FF Bonus": "3.00", "Last Update": "14/03/24"}'

    results = Recon::SpyDataParser.parse_jsonl(input)
    assert_equal 1, results.size

    row = results.first
    assert_equal 111, row.player_id
    assert_equal "Alice", row.name
    assert_equal 100, row.level
    assert_equal 1000, row.strength
    assert_equal 2000, row.defense
    assert_equal 500, row.speed
    assert_equal 300, row.dexterity
    assert_equal Date.new(2024, 3, 14), row.spied_at
  end

  test "jsonl: parses multiple lines" do
    input = <<~JSONL
      {"Name": "Alice [111]", "Level": "100", "Strength": "1,000", "Defense": "2,000", "Speed": "500", "Dexterity": "300", "Total": "3,800", "FF Bonus": "3.00", "Last Update": "14/03/24"}
      {"Name": "Bob [222]", "Level": "50", "Strength": "500", "Defense": "500", "Speed": "100", "Dexterity": "100", "Total": "1,200", "FF Bonus": "3.00", "Last Update": "01/07/23"}
    JSONL

    results = Recon::SpyDataParser.parse_jsonl(input)
    assert_equal 2, results.size
  end

  test "jsonl: strips commas from large numbers" do
    input = '{"Name": "Tim [179208]", "Level": "100", "Strength": "1,000,004,235,571,900", "Defense": "1,232,505,463", "Speed": "423,436,139,476", "Dexterity": "5,017,752,739,987", "Total": "1,005,446,656,956,826", "FF Bonus": "3.00", "Last Update": "17/02/26"}'

    row = Recon::SpyDataParser.parse_jsonl(input).first
    assert_equal 1_000_004_235_571_900, row.strength
    assert_equal 1_232_505_463, row.defense
  end

  test "jsonl: skips lines without valid player ID" do
    input = '{"Name": "BadData", "Strength": "100", "Last Update": "14/03/24"}'

    results = Recon::SpyDataParser.parse_jsonl(input)
    assert_equal 0, results.size
  end

  test "jsonl: skips lines without valid date" do
    input = '{"Name": "Alice [111]", "Strength": "100", "Defense": "100", "Speed": "100", "Dexterity": "100", "Last Update": "N/A"}'

    results = Recon::SpyDataParser.parse_jsonl(input)
    assert_equal 0, results.size
  end

  test "jsonl: skips malformed JSON lines" do
    input = <<~JSONL
      not valid json
      {"Name": "Alice [111]", "Level": "100", "Strength": "1,000", "Defense": "2,000", "Speed": "500", "Dexterity": "300", "Total": "3,800", "FF Bonus": "3.00", "Last Update": "14/03/24"}
    JSONL

    results = Recon::SpyDataParser.parse_jsonl(input)
    assert_equal 1, results.size
    assert_equal 111, results.first.player_id
  end

  test "jsonl: returns empty array for empty input" do
    assert_equal [], Recon::SpyDataParser.parse_jsonl("")
    assert_equal [], Recon::SpyDataParser.parse_jsonl(nil)
  end
end
