module TmCompanyTestHelper
  def tm_company_fixture(name)
    JSON.parse(file_fixture("tm_company/#{name}.json").read)
  end

  def director_job(company_id: 127301, position: "Director")
    TornApi::User::Job::JobData.new(type: "company", company_id: company_id, company_type_id: 28, company_name: "Test Oil Co", rating: 7, position: position)
  end

  def tracked_director(user = users(:bert), company_id: 127301)
    user.update!(company_id: company_id, company_director: true)
    user.set_company_api_key!("COMPANY_KEY_#{user.id}", "Limited Access")
    grant_subscription(user, expires_at: 1.week.from_now)
    user
  end

  def stub_company_types
    types = tm_company_fixture("torn_companies").index_by { |type| type["id"] }
    TmCompany::CompanyTypes.stubs(:all).returns(types)
  end

  def captured_day(company_id: 127301, date: Date.current, **overrides)
    CompanyDay.create!(
      {
        company_torn_id: company_id,
        date: date,
        captured_at: Time.current,
        profile: tm_company_fixture("profile").merge("id" => company_id),
        employees: tm_company_fixture("employees"),
        stock: tm_company_fixture("stock"),
        detailed: tm_company_fixture("detailed")
      }.merge(overrides)
    )
  end
end
