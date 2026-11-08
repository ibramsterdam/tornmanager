require "test_helper"

class TornApi::User::JobTest < ActiveSupport::TestCase
  test "reads a director job" do
    service = TornApi::User::Job.new("key")
    service.expects(:get).with("v2/user/job").returns(
      "job" => { "type" => "company", "id" => 127301, "type_id" => 28, "name" => "Crude Awakening", "rating" => 7, "position" => "Director", "days_in_company" => 124 }
    )

    job = service.fetch

    assert job.director?
    assert_equal 127301, job.company_id
    assert_equal 28, job.company_type_id
  end

  test "is not a director without a company job" do
    service = TornApi::User::Job.new("key")
    service.expects(:get).returns("job" => nil)

    assert_not service.fetch.director?
  end
end
