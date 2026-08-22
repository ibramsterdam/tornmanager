module TornApi
  module CsvResponse
    private

    def parse_body(body)
      body = body.dup.force_encoding(Encoding::UTF_8)
      body = body.scrub unless body.valid_encoding?
      return JSON.parse(body) if body.lstrip.start_with?("{")
      body
    end
  end
end
