class Recon::SpyDataParser
  SpyRow = Data.define(:player_id, :name, :level, :strength, :defense, :speed, :dexterity, :spied_at)

  HEADER_PATTERN = /\bName\b.*\bLevel\b/i
  AVERAGE_PATTERN = /^Average:/i
  NAME_ID_PATTERN = /^(?:\d+\s+)?(.+?)\s*\[(\d+)\]$/

  def self.parse(input)
    return [] if input.blank?

    input.each_line.filter_map do |line|
      line = line.strip
      next if line.blank?
      next if line.match?(HEADER_PATTERN)
      next if line.match?(AVERAGE_PATTERN)

      parse_row(line)
    end
  end

  def self.parse_row(line)
    cols = line.split("\t").map(&:strip)
    return nil if cols.size < 8

    cols.shift if cols[0].match?(/\A\d+\z/)

    name, player_id = extract_name_and_id(cols[0])
    return nil unless player_id

    if format_with_faction?(cols)
      parse_format_1(cols, name, player_id)
    else
      parse_format_2(cols, name, player_id)
    end
  end

  # Format 1: Name, Level, Faction, STR, DEF, SPD, DEX, Total, FF, Date
  def self.parse_format_1(cols, name, player_id)
    return nil if cols.size < 10

    date = parse_date(cols[9])
    return nil unless date

    SpyRow.new(
      player_id: player_id,
      name: name,
      level: parse_level(cols[1]),
      strength: parse_number(cols[3]),
      defense: parse_number(cols[4]),
      speed: parse_number(cols[5]),
      dexterity: parse_number(cols[6]),
      spied_at: date
    )
  end

  # Format 2: Name, Level, STR, DEF, SPD, DEX, Total, Date, LastAction, Score
  def self.parse_format_2(cols, name, player_id)
    return nil if cols.size < 8
    return nil if cols[2] == "N/A"

    date = parse_date(cols[7])
    return nil unless date

    SpyRow.new(
      player_id: player_id,
      name: name,
      level: parse_level(cols[1]),
      strength: parse_number(cols[2]),
      defense: parse_number(cols[3]),
      speed: parse_number(cols[4]),
      dexterity: parse_number(cols[5]),
      spied_at: date
    )
  end

  def self.format_with_faction?(cols)
    # Format 1 has date at index 9 (DD/MM/YY), format 2 has date at index 7
    # Check which position contains a valid date
    cols[9]&.match?(%r{\A\d{2}/\d{2}/\d{2}\z})
  end

  def self.extract_name_and_id(col)
    match = col.match(NAME_ID_PATTERN)
    return [ nil, nil ] unless match

    [ match[1].strip, match[2].to_i ]
  end

  def self.parse_number(str)
    str&.gsub(",", "")&.to_i || 0
  end

  def self.parse_level(str)
    return nil if str == "Unknown"
    str&.to_i
  end

  def self.parse_date(str)
    return nil if str.blank? || str == "N/A"
    parts = str.split("/")
    return nil unless parts.size == 3

    day, month, year = parts.map(&:to_i)
    year += 2000 if year < 100
    Date.new(year, month, day)
  rescue Date::Error
    nil
  end

  def self.parse_jsonl(input)
    return [] if input.blank?

    input.each_line.filter_map do |line|
      line = line.strip
      next if line.empty?

      parse_jsonl_line(line)
    end
  end

  def self.parse_jsonl_line(line)
    data = JSON.parse(line)
    _, player_id = extract_name_and_id(data["Name"])
    return nil unless player_id

    spied_at = parse_date(data["Last Update"])
    return nil unless spied_at

    SpyRow.new(
      player_id: player_id,
      name: data["Name"]&.sub(/\s*\[\d+\]\s*$/, ""),
      level: data["Level"]&.to_i,
      strength: parse_number(data["Strength"]),
      defense: parse_number(data["Defense"]),
      speed: parse_number(data["Speed"]),
      dexterity: parse_number(data["Dexterity"]),
      spied_at: spied_at
    )
  rescue JSON::ParserError
    nil
  end

  private_class_method :parse_row, :parse_format_1, :parse_format_2, :parse_jsonl_line,
    :format_with_faction?, :extract_name_and_id, :parse_number, :parse_level, :parse_date
end
