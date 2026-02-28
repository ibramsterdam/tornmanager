require "test_helper"

class ScriptVersionTest < ActiveSupport::TestCase
  test "validates presence of version" do
    version = ScriptVersion.new(released_at: Date.current, script_content: "// script")
    assert_not version.valid?
    assert_includes version.errors[:version], "can't be blank"
  end

  test "validates uniqueness of version" do
    ScriptVersion.create!(version: "1.0.0", released_at: Date.current, script_content: "// script")
    duplicate = ScriptVersion.new(version: "1.0.0", released_at: Date.current, script_content: "// script")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:version], "has already been taken"
  end

  test "validates presence of released_at" do
    version = ScriptVersion.new(version: "1.0.0", script_content: "// script")
    assert_not version.valid?
    assert_includes version.errors[:released_at], "can't be blank"
  end

  test "validates presence of script_content" do
    version = ScriptVersion.new(version: "1.0.0", released_at: Date.current)
    assert_not version.valid?
    assert_includes version.errors[:script_content], "can't be blank"
  end

  test "ordered scope returns newest first" do
    versions = ScriptVersion.ordered
    assert_equal "0.2.0", versions.first.version
    assert_equal "0.1.0", versions.last.version
  end

  test "latest returns the most recent version" do
    assert_equal "0.2.0", ScriptVersion.latest.version
  end
end
