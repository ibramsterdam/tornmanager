require "test_helper"

class FactionHelperTest < ActionView::TestCase
  include FactionHelper

  test "activity_cell_rgb returns red for zero intensity" do
    rgb = activity_cell_rgb(0, 10)
    assert_equal "239, 68, 68", rgb
  end

  test "activity_cell_rgb returns green for max intensity" do
    rgb = activity_cell_rgb(10, 10)
    assert_equal "34, 197, 94", rgb
  end

  test "activity_cell_rgb returns yellow for mid intensity" do
    rgb = activity_cell_rgb(5, 10)
    assert_equal "234, 179, 8", rgb
  end

  test "activity_cell_rgb handles zero max gracefully" do
    rgb = activity_cell_rgb(0, 0)
    assert_equal "239, 68, 68", rgb
  end
end
