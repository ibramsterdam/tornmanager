module User::Employable
  extend ActiveSupport::Concern

  included do
    belongs_to :company, optional: true, primary_key: :torn_id

    scope :employed, -> { where.not(company_id: nil) }
    scope :with_working_stats, -> { where.not(working_stats: nil) }
  end

  def employed?
    company_id.present?
  end

  def faction_mate_of_director?
    faction_torn_id.present? && company&.director_faction_torn_id == faction_torn_id
  end

  def disconnect_from_company
    update!(company_id: nil, company_director: false)
  end
end
