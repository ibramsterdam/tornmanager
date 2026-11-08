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
end
