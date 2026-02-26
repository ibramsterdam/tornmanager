module SessionTestHelper
  def sign_in_as(user)
    Current.session = user.sessions.create!

    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies["session_id"] = cookie_jar[:session_id]
    end
  end

  # Signs in via the full SessionsController flow, which sets session[:torn_faction_id].
  # Use this when testing flows that depend on the faction ID being in the session.
  def sign_in_with_faction_id(user, torn_faction_id, access_type: "Public Only")
    sign_in_as(user)

    access_level = access_type == "Limited Access" ? 3 : 1
    key_info = TornApi::Key::Info::InfoData.new(
      access: TornApi::Key::Info::AccessData.new(level: access_level, type: access_type, faction: false, company: false),
      user: TornApi::Key::Info::UserData.new(id: user.torn_id, faction_id: torn_faction_id, company_id: 0)
    )
    profile = TornApi::User::Profile::ProfileData.new(
      id: user.torn_id, name: user.name, level: user.level, image: nil
    )

    TornApi::Key::Info.any_instance.stubs(:fetch).returns(key_info)
    TornApi::User::Profile.any_instance.stubs(:fetch).returns(profile)

    post session_path, params: { api_key: user.api_key, terms_accepted: "1" }

    TornApi::Key::Info.any_instance.unstub(:fetch)
    TornApi::User::Profile.any_instance.unstub(:fetch)
  end

  def sign_out
    Current.session&.destroy!
    cookies.delete("session_id")
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
