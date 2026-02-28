require "test_helper"

class UserscriptControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bram)
  end

  test "index requires authentication" do
    get userscript_path
    assert_redirected_to new_session_path
  end

  test "index shows userscript page when authenticated" do
    sign_in_as(@user)
    get userscript_path
    assert_response :success
    assert_select "h1", "TornManager Script"
  end

  test "index shows install button with latest version" do
    sign_in_as(@user)
    get userscript_path
    assert_response :success
    assert_match "Install v0.2.0", response.body
  end

  test "index shows version history" do
    sign_in_as(@user)
    get userscript_path
    assert_response :success
    assert_select ".version-number", text: "0.2.0"
    assert_select ".version-number", text: "0.1.0"
  end

  test "download requires authentication" do
    get userscript_download_path
    assert_redirected_to new_session_path
  end

  test "download serves the script content" do
    sign_in_as(@user)
    get userscript_download_path
    assert_response :success
    assert_equal "text/javascript", response.content_type
    assert_includes response.body, "@version 0.2.0"
  end

  test "download redirects when no script content available" do
    ScriptVersion.update_all(script_content: nil)
    sign_in_as(@user)
    get userscript_download_path
    assert_redirected_to userscript_path
  end
end
