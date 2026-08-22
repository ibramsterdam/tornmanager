module TornApi
  module CsvResponse
    private

    def parse_body(body)
      return JSON.parse(body) if body.lstrip.start_with?("{")
      body
    end
  end
end
