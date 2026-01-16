class Torn::Stock < ApplicationRecord
  MONEY_MAKING_ACRONYMS = %w[ LAG IOU GRN THS TCT TMI FHG SYM PRN EWM MUN PTS ].freeze
  ACRONYM_TO_TORN_ITEM_ID = {
    "EWM" => 364,
    "THS" => 365,
    "PRN" => 366,
    "FHG" => 367,
    "LAG" => 368,
    "LSC" => 369,
    "SYM" => 370,
    "ASS" => 817,
    "MUN" => 818
  }.freeze

  scope :money_makers, -> { where(acronym: MONEY_MAKING_ACRONYMS) }

  def self.money_rows(owned_stocks)
    money_makers.flat_map do |stock|
      owned_stock = owned_stocks.find { |os| os.stock_id == stock.torn_id }

      (1..4).map do |increment|
        {
          stock_name: "#{stock.name} (#{stock.acronym})",
          increment: increment,
          dividend_value: stock.dividend_value,
          block_cost: stock.block_cost(increment),
          days_to_break_even: stock.days_to_break_even_with_item(stock.dividend_value, increment),
          owned: owned_stock ? stock.owns_increment?(increment, owned_stock.total_shares) : false
        }
      end
    end
  end

  def block_cost(increment)
    current_price * dividend_requirement * (2**(increment - 1))
  end

  def days_to_break_even_with_item(item_market_price, increment)
    cost = block_cost(increment)
    payout = item_market_price.to_i
    return Float::INFINITY if payout == 0
    payout_days = dividend_frequency
    (cost / payout).ceil * payout_days
  end

  def owns_increment?(increment, owned_shares)
    required_shares = dividend_requirement * (2**(increment - 1))
    owned_shares >= required_shares
  end
end
