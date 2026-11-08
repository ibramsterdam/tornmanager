class CompanyDay < ApplicationRecord
  belongs_to :user, optional: true

  scope :for_company, ->(company_torn_id) { where(company_torn_id: company_torn_id) }
end
