class Torn::Item < ApplicationRecord
  STOCK_DIVIDEND_ITEM_IDS = [ 364, 365, 366, 367, 368, 369, 370, 817, 818 ].freeze
  scope :money_makers, -> { where(torn_id: STOCK_DIVIDEND_ITEM_IDS) }
end
