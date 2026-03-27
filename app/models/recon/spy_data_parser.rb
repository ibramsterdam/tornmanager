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
    cols = line.split("\t")
    return nil if cols.size < 8

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

    SpyRow.new(
      player_id: player_id,
      name: name,
      level: parse_level(cols[1]),
      strength: parse_number(cols[3]),
      defense: parse_number(cols[4]),
      speed: parse_number(cols[5]),
      dexterity: parse_number(cols[6]),
      spied_at: parse_date(cols[9])
    )
  end

  # Format 2: Name, Level, STR, DEF, SPD, DEX, Total, Date, LastAction, Score
  def self.parse_format_2(cols, name, player_id)
    return nil if cols.size < 8
    return nil if cols[2]&.strip == "N/A"

    SpyRow.new(
      player_id: player_id,
      name: name,
      level: parse_level(cols[1]),
      strength: parse_number(cols[2]),
      defense: parse_number(cols[3]),
      speed: parse_number(cols[4]),
      dexterity: parse_number(cols[5]),
      spied_at: parse_date(cols[7])
    )
  end

  # Format 1 has a faction column (cols[2]) that's text like "None", "|HT|", etc.
  # Format 2 has stats in cols[2] which are numbers or "N/A"
  def self.format_with_faction?(cols)
    col2 = cols[2]&.strip
    return false if col2.nil?
    return false if col2 == "N/A"

    # If it looks like a number (with commas), it's format 2
    !col2.match?(/\A[\d,]+\z/)
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
    return nil if str&.strip == "Unknown"
    str&.to_i
  end

  def self.parse_date(str)
    return nil if str.blank? || str.strip == "N/A"
    day, month, year = str.strip.split("/").map(&:to_i)
    year += 2000 if year < 100
    Date.new(year, month, day)
  end

  private_class_method :parse_row, :parse_format_1, :parse_format_2,
    :format_with_faction?, :extract_name_and_id, :parse_number, :parse_level, :parse_date
end
