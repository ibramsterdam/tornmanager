require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  setup do
    @company = companies(:adult_novelties)
    @bert = users(:bert)
  end

  test "employees joins users through torn company ids" do
    assert_includes @company.employees, @bert
    assert_equal @company, @bert.company
  end

  test "employed scope returns only users with a company" do
    assert_includes User.employed, @bert
    assert_not_includes User.employed, users(:bram)
  end

  test "disconnect_from_company clears employment but keeps the user" do
    @bert.update!(company_director: true)

    @bert.disconnect_from_company

    @bert.reload
    assert_nil @bert.company_id
    assert_not @bert.company_director
    assert_equal 250_000, @bert.working_stats
    assert User.exists?(@bert.id)
  end
end
