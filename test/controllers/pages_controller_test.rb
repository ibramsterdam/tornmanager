require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "the legal page has the company documents" do
    get legal_path

    assert_response :success
    assert_select "#company-privacy-policy"
    assert_select "#company-terms-of-service"
  end

  test "every table of contents link points to a section" do
    get legal_path

    targets = css_select(".legal-toc a").map { |link| link["href"].delete_prefix("#") }
    missing = targets.reject { |id| css_select("##{id}").any? }

    assert_empty missing
  end
end
