class CompanySnapshot < ApplicationRecord
  BATCH_SIZE = 2_000
  RETENTION = 90.days

  def self.record!(rows, date)
    rows.each_slice(BATCH_SIZE) do |slice|
      upsert_all(
        slice.map { |row| attributes_for(row, date) },
        unique_by: [ :company_torn_id, :date ]
      )
    end
  end

  def self.attributes_for(row, date)
    {
      company_torn_id: row.torn_id,
      date: date,
      company_type_id: row.company_type_id,
      rating: row.rating,
      employees_hired: row.employees_hired,
      employees_capacity: row.employees_capacity,
      daily_income: row.daily_income,
      daily_customers: row.daily_customers,
      weekly_income: row.weekly_income,
      weekly_customers: row.weekly_customers
    }
  end
end
