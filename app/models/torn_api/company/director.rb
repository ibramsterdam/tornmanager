module TornApi
  module Company
    class Director < Base
      COMMENT = "tmcompany".freeze
      NEWS_PAGE_SIZE = 100
      NEWS_MAX_PAGES = 5

      def profile
        get("v2/company/profile", params)["profile"]
      end

      def employees
        get("v2/company/employees", params)["employees"]
      end

      def stock
        get("v2/company/stock", params)["stock"]
      end

      def detailed
        get("company", params(selections: "detailed"))["company_detailed"]
      end

      def news(since: nil)
        entries = []
        cursor = nil

        NEWS_MAX_PAGES.times do
          query = params(cat: "all", limit: NEWS_PAGE_SIZE, striptags: true)
          query[:from] = since.to_i if since
          query[:to] = cursor if cursor
          batch = Array(get("v2/company/news", query)["news"])
          entries.concat(batch)
          break if batch.size < NEWS_PAGE_SIZE

          cursor = batch.map { |entry| entry["timestamp"] }.min - 1
        end

        entries
      end

      private

      def params(extra = {})
        { comment: COMMENT }.merge(extra)
      end
    end
  end
end
