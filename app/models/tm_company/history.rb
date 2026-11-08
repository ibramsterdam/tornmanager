module TmCompany
  class History
    def initialize(company_torn_id, days:)
      @company_torn_id = company_torn_id
      @dates = ((Date.current - (days - 1))..Date.current).to_a
    end

    def as_json(*)
      own = CompanySnapshot.where(company_torn_id: @company_torn_id, date: @dates).index_by(&:date)
      captured = CompanyDay.for_company(@company_torn_id).where(date: @dates).index_by(&:date)
      peers = peer_per_employee(own)

      {
        dates: @dates,
        series: {
          income: @dates.map { |date| own[date]&.daily_income || captured[date]&.profile&.dig("income", "daily") },
          customers: @dates.map { |date| own[date]&.daily_customers || captured[date]&.profile&.dig("customers", "daily") },
          income_per_employee: @dates.map { |date| per_employee(own[date]) || captured_per_employee(captured[date]) },
          peer_median_per_employee: @dates.map { |date| peers.dig(date, :median) },
          peer_top_per_employee: @dates.map { |date| peers.dig(date, :top) },
          wages: @dates.map { |date| wages(captured[date]) },
          effectiveness: @dates.map { |date| average_effectiveness(captured[date]) },
          funds: @dates.map { |date| captured[date]&.detailed&.dig("company_funds") },
          popularity: @dates.map { |date| captured[date]&.detailed&.dig("popularity") },
          efficiency: @dates.map { |date| captured[date]&.detailed&.dig("efficiency") },
          environment: @dates.map { |date| captured[date]&.detailed&.dig("environment") }
        }
      }
    end

    private

    def per_employee(snapshot)
      return unless snapshot&.daily_income && snapshot.employees_hired.to_i.positive?

      snapshot.daily_income / snapshot.employees_hired
    end

    def captured_per_employee(day)
      income = day&.profile&.dig("income", "daily")
      hired = day&.profile&.dig("employees", "hired").to_i
      income / hired if income && hired.positive?
    end

    def peer_per_employee(own)
      latest = own.values.max_by(&:date)
      return {} unless latest

      CompanySnapshot
        .where(company_type_id: latest.company_type_id, rating: latest.rating, date: @dates)
        .where("employees_hired > 0")
        .pluck(:date, :daily_income, :employees_hired)
        .group_by(&:first)
        .transform_values do |rows|
          values = rows.map { |_, income, hired| income.to_i / hired }.sort
          { median: values[((values.size - 1) * 0.5).round], top: values[((values.size - 1) * 0.9).round] }
        end
    end

    def wages(day)
      wages = Array(day&.employees).filter_map { |employee| employee["wage"] }
      wages.sum if wages.any?
    end

    def average_effectiveness(day)
      totals = Array(day&.employees).filter_map { |employee| employee.dig("effectiveness", "total") }
      (totals.sum.to_f / totals.size).round(1) if totals.any?
    end
  end
end
