require "test_helper"

class TornApi::Company::EmployeesTest < ActiveSupport::TestCase
  test "parses employees with online state and position" do
    response = {
      "employees" => [
        {
          "id" => 1234567,
          "last_action" => { "status" => "Online", "relative" => "0 minutes ago", "timestamp" => 1755800000 },
          "position" => "Employee",
          "days_in_company" => 45
        },
        {
          "id" => 7777777,
          "position" => { "name" => "Manager" }
        }
      ]
    }
    service = TornApi::Company::Employees.new("test_key", 91001)
    service.expects(:get)
      .with("v2/company/91001/employees", { comment: "tmrecruiter" })
      .returns(response)

    employees = service.fetch

    first = employees.first
    assert_equal 1234567, first.torn_id
    assert_equal "Online", first.status
    assert_equal "0 minutes ago", first.relative
    assert_equal 1755800000, first.last_action_at
    assert_equal "Employee", first.position
    assert_equal 45, first.days_in_company

    second = employees.last
    assert_equal "Offline", second.status
    assert_equal "Manager", second.position
    assert_nil second.days_in_company
  end
end
