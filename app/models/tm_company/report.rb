module TmCompany
  class Report
    include ActiveSupport::NumberHelper

    STATS = %w[manual_labor intelligence endurance].freeze
    SETTLING_DAYS = 7
    LOW_EFFECTIVENESS = 70
    INACTIVE_AFTER = 3.days
    LOW_STOCK_DAYS = 2
    MAX_TRAINS = 20

    def initialize(day)
      @day = day
      @profile = day.profile || {}
      @detailed = day.detailed || {}
      @employees = Array(day.employees)
      @stock = Array(day.stock)
      @type = CompanyTypes.find(@profile.dig("type", "id")) || {}
    end

    def as_json(*)
      {
        company: company,
        benchmark: benchmark,
        employees: employee_rows,
        balance: balance,
        stock: stock_rows,
        advice: advice
      }
    end

    def company
      @company ||= {
        id: @profile["id"],
        name: @profile["name"],
        type_id: @profile.dig("type", "id"),
        type_name: @profile.dig("type", "name"),
        rating: @profile["rating"],
        hired: @profile.dig("employees", "hired"),
        capacity: @profile.dig("employees", "capacity"),
        income_daily: @profile.dig("income", "daily"),
        income_weekly: @profile.dig("income", "weekly"),
        customers_daily: @profile.dig("customers", "daily"),
        customers_weekly: @profile.dig("customers", "weekly"),
        wages_daily: wages_daily,
        advertising_daily: @detailed["advertising_budget"],
        profit_daily: profit_daily,
        funds: @detailed["company_funds"],
        popularity: @detailed["popularity"],
        efficiency: @detailed["efficiency"],
        environment: @detailed["environment"],
        trains: @detailed["trains_available"],
        captured_at: @day.captured_at
      }
    end

    def benchmark
      return @benchmark if defined?(@benchmark)

      date = CompanySnapshot.where(company_type_id: company[:type_id], rating: company[:rating]).maximum(:date)
      return @benchmark = nil unless date

      peers = CompanySnapshot.where(company_type_id: company[:type_id], rating: company[:rating], date: date)
        .pluck(:company_torn_id, :daily_income, :employees_hired)
      per_employee = peers.map { |_, income, hired| income.to_i / [ hired.to_i, 1 ].max }.sort
      ranked = peers.sort_by { |_, income, _| -income.to_i }.map(&:first)

      @benchmark = {
        date: date,
        peers: peers.size,
        rank: ranked.index(company[:id])&.succ,
        income_per_employee: income_per_employee,
        median_per_employee: percentile(per_employee, 0.5),
        top_per_employee: percentile(per_employee, 0.9)
      }
    end

    def employee_rows
      @employee_rows ||= @employees.map do |employee|
        position = employee.dig("position", "name")
        required = required_stats(position)
        stats = employee["stats"] || {}
        effectiveness = employee["effectiveness"] || {}

        {
          id: employee["id"],
          name: employee["name"],
          position: position,
          days_in_company: employee["days_in_company"],
          status: employee.dig("status", "description"),
          last_action: employee.dig("last_action", "relative"),
          stats: stats,
          required: required,
          effectiveness: effectiveness,
          wage: employee["wage"],
          value: employee["value"],
          flags: flags_for(employee, required, stats, effectiveness)
        }
      end
    end

    def balance
      @balance ||= begin
        counts = @employees.map { |employee| employee.dig("position", "name") }.tally
        positions = Array(@type["positions"]).map do |position|
          { name: position["name"], ability: ability(position), count: counts.fetch(position["name"], 0) }
        end
        {
          positions: positions,
          missing_abilities: positions.select { |position| position[:ability] && position[:count].zero? }.map { |position| position[:ability] }.uniq
        }
      end
    end

    def stock_rows
      @stock_rows ||= @stock.map do |item|
        sold = item["sold_amount"].to_i
        {
          name: item["name"],
          cost: item["cost"],
          price: item["price"],
          rrp: item["rrp"],
          in_stock: item["in_stock"],
          on_order: item["on_order"],
          sold_amount: item["sold_amount"],
          sold_worth: item["sold_worth"],
          days_left: sold.positive? ? (item["in_stock"].to_i + item["on_order"].to_i).fdiv(sold).round(1) : nil
        }
      end
    end

    def advice
      [
        trainer_advice,
        trains_advice,
        empty_slots_advice,
        benchmark_advice,
        profit_advice,
        *flagged_employee_advice,
        *stock_advice,
        cleaner_advice
      ].compact
    end

    private

    def wages_daily
      wages = @employees.filter_map { |employee| employee["wage"] }
      wages.sum if wages.any?
    end

    def profit_daily
      return unless company_income && wages_daily

      company_income - wages_daily - @detailed["advertising_budget"].to_i
    end

    def company_income
      @profile.dig("income", "daily")
    end

    def income_per_employee
      hired = @profile.dig("employees", "hired").to_i
      company_income.to_i / hired if hired.positive?
    end

    def percentile(sorted, fraction)
      return if sorted.empty?

      sorted[((sorted.size - 1) * fraction).round]
    end

    def required_stats(position)
      Array(@type["positions"]).find { |item| item["name"] == position }&.dig("working_stats", "required") || {}
    end

    def ability(position)
      value = position["ability"]
      value unless value.blank? || value == "None"
    end

    def flags_for(employee, required, stats, effectiveness)
      flags = []
      flags << "addicted" if effectiveness["addiction"].to_i.negative?
      flags << "inactive" if effectiveness["inactivity"].to_i.negative? || inactive?(employee)
      flags << "below_requirement" if STATS.any? { |stat| required[stat].to_i.positive? && stats.key?(stat) && stats[stat].to_i < required[stat].to_i }
      flags << "low_effectiveness" if effectiveness.key?("total") && effectiveness["total"].to_i < LOW_EFFECTIVENESS
      flags << "settling_in" if employee["days_in_company"].to_i < SETTLING_DAYS
      flags << "costs_more_than_value" if employee["value"] && employee["wage"] && employee["wage"] > employee["value"]
      flags
    end

    def inactive?(employee)
      timestamp = employee.dig("last_action", "timestamp")
      timestamp.present? && Time.zone.at(timestamp) < INACTIVE_AFTER.ago
    end

    def trainer_advice
      trainer = balance[:positions].find { |position| position[:ability] == "Trainer" }
      return unless trainer && trainer[:count].zero?

      tip("warning", "No #{trainer[:name]} on staff", "The #{trainer[:name]} is your Trainer. Trainers add extra trains every day, so your staff improve faster.")
    end

    def trains_advice
      trains = @detailed["trains_available"]
      return unless trains && trains >= MAX_TRAINS

      tip("warning", "Trains are full", "You have #{trains} trains saved, the maximum. New trains are lost until you use some.")
    end

    def empty_slots_advice
      hired = company[:hired].to_i
      capacity = company[:capacity].to_i
      return unless capacity > hired && income_per_employee

      empty = capacity - hired
      tip("tip", "#{empty} empty #{'slot'.pluralize(empty)}", "You have room for #{empty} more. At your current income per employee that is about $#{money(income_per_employee * empty)} more a day.")
    end

    def benchmark_advice
      return unless benchmark && benchmark[:median_per_employee] && income_per_employee

      median = benchmark[:median_per_employee]
      if income_per_employee < median
        tip("warning", "Below the median", "You make $#{money(income_per_employee)} per employee a day. The median for #{company[:rating]} star #{company[:type_name]} companies is $#{money(median)}.")
      else
        tip("good", "Above the median", "You make $#{money(income_per_employee)} per employee a day, against a median of $#{money(median)} for #{company[:rating]} star #{company[:type_name]} companies. You rank #{benchmark[:rank]} of #{benchmark[:peers]}.")
      end
    end

    def profit_advice
      profit = profit_daily
      return unless profit&.negative?

      tip("warning", "Losing money", "Wages and advertising cost more than your income: $#{money(profit.abs)} a day.")
    end

    def flagged_employee_advice
      {
        "addicted" => [ "warning", "addicted", "Addiction lowers their effectiveness and your environment." ],
        "inactive" => [ "warning", "inactive", "Inactive staff lower effectiveness and environment." ],
        "below_requirement" => [ "tip", "below the stat requirement", "Train them, or move them to a position that fits their stats." ],
        "low_effectiveness" => [ "warning", "below #{LOW_EFFECTIVENESS}% effectiveness", "Check their effectiveness breakdown on the Staff screen." ]
      }.filter_map do |flag, (level, label, detail)|
        names = employee_rows.select { |row| row[:flags].include?(flag) }.map { |row| row[:name] }
        tip(level, "#{names.size} #{'employee'.pluralize(names.size)} #{label}", "#{names.to_sentence}. #{detail}") if names.any?
      end
    end

    def stock_advice
      stock_rows.filter_map do |item|
        next unless item[:days_left] && item[:days_left] < LOW_STOCK_DAYS

        tip("warning", "#{item[:name]} runs out soon", "#{item[:in_stock]} in stock and #{item[:on_order]} on order is about #{item[:days_left]} days of sales.")
      end
    end

    def cleaner_advice
      environment = @detailed["environment"]
      return unless environment && environment < 80 && balance[:missing_abilities].include?("Cleaner")

      cleaner = balance[:positions].find { |position| position[:ability] == "Cleaner" }
      tip("tip", "Environment is #{environment}%", "A #{cleaner[:name]} works as a Cleaner and raises environment. You have none.")
    end

    def tip(level, title, detail)
      { level: level, title: title, detail: detail }
    end

    def money(amount)
      number_to_delimited(amount)
    end
  end
end
