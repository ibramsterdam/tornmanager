require "test_helper"

class Admin::ScriptVersionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:bram)
    @version = script_versions(:initial)
    @script_file = Rack::Test::UploadedFile.new(
      StringIO.new("// ==UserScript==\n// @version 0.3.0\n// ==/UserScript=="),
      "text/javascript",
      false,
      original_filename: "tornmanager.user.js"
    )
    sign_in_as(@admin)
  end

  test "index requires admin" do
    sign_out
    get admin_script_versions_path
    assert_redirected_to new_session_path
  end

  test "index lists all versions" do
    get admin_script_versions_path
    assert_response :success
    assert_select ".version-number", text: "0.1.0"
    assert_select ".version-number", text: "0.2.0"
  end

  test "create adds a new version with uploaded file" do
    assert_difference "ScriptVersion.count", 1 do
      post admin_script_versions_path, params: {
        script_version: {
          version: "0.3.0",
          changelog: "Bug fixes",
          released_at: Date.current,
          script_file: @script_file
        }
      }
    end
    assert_redirected_to admin_script_versions_path
    assert_equal "Script version 0.3.0 created.", flash[:notice]

    created = ScriptVersion.find_by(version: "0.3.0")
    assert_includes created.script_content, "@version 0.3.0"
  end

  test "create without file fails validation" do
    assert_no_difference "ScriptVersion.count" do
      post admin_script_versions_path, params: {
        script_version: { version: "0.3.0", changelog: "No file", released_at: Date.current }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create with duplicate version fails" do
    assert_no_difference "ScriptVersion.count" do
      post admin_script_versions_path, params: {
        script_version: {
          version: "0.1.0",
          changelog: "Duplicate",
          released_at: Date.current,
          script_file: @script_file
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "edit shows form" do
    get edit_admin_script_version_path(@version)
    assert_response :success
    assert_select "input[value='0.1.0']"
  end

  test "update changes version attributes without replacing file" do
    patch admin_script_version_path(@version), params: {
      script_version: { changelog: "Updated changelog" }
    }
    assert_redirected_to admin_script_versions_path
    assert_equal "Updated changelog", @version.reload.changelog
    assert @version.script_content.present?
  end

  test "update replaces file when new one is uploaded" do
    new_file = Rack::Test::UploadedFile.new(
      StringIO.new("// replaced content"),
      "text/javascript",
      false,
      original_filename: "tornmanager.user.js"
    )

    patch admin_script_version_path(@version), params: {
      script_version: { script_file: new_file }
    }
    assert_redirected_to admin_script_versions_path
    assert_equal "// replaced content", @version.reload.script_content
  end

  test "update with invalid data re-renders edit" do
    patch admin_script_version_path(@version), params: {
      script_version: { version: "" }
    }
    assert_response :unprocessable_entity
  end

  test "destroy deletes the version" do
    assert_difference "ScriptVersion.count", -1 do
      delete admin_script_version_path(@version)
    end
    assert_redirected_to admin_script_versions_path
    assert_equal "Script version 0.1.0 deleted.", flash[:notice]
  end
end
