require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "hof_access? returns true for admin" do
    assert users(:bram).hof_access?
  end

  test "hof_access? returns true for kaneki" do
    assert users(:kaneki).hof_access?
  end

  test "hof_access? returns false for regular user" do
    assert_not users(:bert).hof_access?
  end
end
