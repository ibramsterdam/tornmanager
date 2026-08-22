module Api
  class RecruiterMatchesController < BaseController
    before_action :require_active_subscription
    rate_limit to: 60, within: 1.minute

    PAGE_SIZE = 100
    MAX_PAGE = 10_000

    def index
      scope = matches_scope
      page = params[:page].to_i.clamp(0, MAX_PAGE)
      players = scope
        .order(working_stats: :desc, torn_id: :asc)
        .offset(page * PAGE_SIZE)
        .limit(PAGE_SIZE)
        .includes(:company)

      render json: {
        matches: players.map { |player| match_json(player) },
        total: scope.count,
        page: page,
        page_size: PAGE_SIZE,
        meta: {
          roster_synced_at: Company.maximum(:synced_at)&.iso8601,
          stats_swept_at: User.maximum(:working_stats_at)&.iso8601
        }
      }
    end

    private

    def matches_scope
      star_min = params.fetch(:star_min, 0).to_i.clamp(0, 10)
      star_max = params.fetch(:star_max, 10).to_i.clamp(0, 10)
      min_stats = [ params[:min_stats].to_i, 1 ].max
      type_ids = Array(params[:type_ids]).map(&:to_i).reject(&:zero?)

      scope = User.employed
        .where(company_director: false)
        .where(working_stats: min_stats..)
        .joins(:company)
        .merge(Company.where(rating: star_min..star_max))
      scope = scope.merge(Company.where(company_type_id: type_ids)) if type_ids.any?
      if params[:exclude_faction_mates].present?
        scope = scope.where(
          "users.faction_torn_id IS NULL OR companies.director_faction_torn_id IS NULL OR users.faction_torn_id != companies.director_faction_torn_id"
        )
      end
      scope
    end

    def match_json(player)
      {
        torn_id: player.torn_id,
        name: player.name,
        level: player.level,
        working_stats: player.working_stats,
        faction_torn_id: player.faction_torn_id,
        faction_mate_of_director: player.faction_mate_of_director?,
        company: {
          torn_id: player.company.torn_id,
          name: player.company.name,
          company_type_id: player.company.company_type_id,
          rating: player.company.rating
        }
      }
    end
  end
end
