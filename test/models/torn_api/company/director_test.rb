require "test_helper"

class TornApi::Company::DirectorTest < ActiveSupport::TestCase
  setup do
    @director = TornApi::Company::Director.new("key")
  end

  test "reads the v2 selections" do
    @director.expects(:get).with("v2/company/employees", { comment: "tmcompany" }).returns("employees" => [ { "id" => 1 } ])
    @director.expects(:get).with("v2/company/stock", { comment: "tmcompany" }).returns("stock" => [ { "id" => 173 } ])
    @director.expects(:get).with("v2/company/profile", { comment: "tmcompany" }).returns("profile" => { "id" => 127301 })

    assert_equal [ { "id" => 1 } ], @director.employees
    assert_equal [ { "id" => 173 } ], @director.stock
    assert_equal 127301, @director.profile["id"]
  end

  test "reads detailed from the v1 api" do
    @director.expects(:get).with("company", { comment: "tmcompany", selections: "detailed" }).returns("company_detailed" => { "popularity" => 78 })

    assert_equal 78, @director.detailed["popularity"]
  end

  test "pages back through news" do
    first = (1..100).map { |i| { "id" => "a#{i}", "timestamp" => 2_000 - i } }
    second = [ { "id" => "b1", "timestamp" => 1_000 } ]
    @director.expects(:get).with("v2/company/news", { comment: "tmcompany", cat: "all", limit: 100, striptags: true, from: 500 }).returns("news" => first)
    @director.expects(:get).with("v2/company/news", { comment: "tmcompany", cat: "all", limit: 100, striptags: true, from: 500, to: 1_899 }).returns("news" => second)

    assert_equal 101, @director.news(since: Time.zone.at(500)).size
  end
end
