class Factions::Leadership::WarReportsController < Factions::Leadership::BaseController
  def show
    @wars = @faction.ranked_wars.completed.recent
    @selected_war = if params[:war].present?
      @wars.find_by(torn_war_id: params[:war])
    else
      @wars.first
    end

    @payout_settings = @faction.faction_setting || @faction.build_faction_setting
    load_war_report if @selected_war
  end

  def save_payout_settings
    setting = @faction.faction_setting || @faction.create_faction_setting!
    setting.update!(
      payout_faction_cut: params[:faction_cut],
      payout_assist_value: params[:assist_value]
    )

    render json: { success: true }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def fetch_attacks
    war = @faction.ranked_wars.find_by!(torn_war_id: params[:war])

    unless @faction.torn_api_key&.faction_access?
      return redirect_to faction_leadership_war_reports_path(@faction, war: war.torn_war_id),
        alert: "API key needs faction API access to fetch attack logs."
    end

    FetchWarAttacksJob.perform_now(war.id)

    redirect_to faction_leadership_war_reports_path(@faction, war: war.torn_war_id),
      notice: "Fetching attack logs for war vs #{war.opponent_faction_name}..."
  end

  private

  def load_war_report
    @attacks = @selected_war.ranked_war_attacks
    @has_attacks = @attacks.exists?

    faction_id = @faction.torn_id
    @outgoing = @attacks.outgoing(faction_id).order(started: :asc)
    @incoming = @attacks.incoming(faction_id).order(started: :asc)

    expected_outgoing = @selected_war.our_attacks || 0
    actual_outgoing = @outgoing.count
    @integrity_ok = actual_outgoing >= expected_outgoing
    @integrity_message = "#{actual_outgoing} / #{expected_outgoing} outgoing attacks collected" unless @integrity_ok

    @attacks_by_member = @outgoing.group_by(&:attacker_id)
    @member_stats = @has_attacks ? calculate_member_stats(@outgoing, faction_id) : []
  end

  def calculate_member_stats(outgoing_attacks, faction_id)
    stats = {}

    outgoing_attacks.each do |attack|
      id = attack.attacker_id
      stats[id] ||= {
        name: attack.attacker_name,
        torn_id: id,
        hits: 0,
        respect: 0.0,
        assists: 0,
        ff_low: 0,       # FF < 1.25
        ff_mid: 0,        # 1.25 <= FF < 1.75
        ff_high: 0,       # FF >= 1.75
        warlord_hits: 0,
        overseas_hits: 0,
        total_ff: 0.0
      }

      ff = attack.fair_fight || 0

      if attack.result == "Assist"
        stats[id][:assists] += 1
      else
        stats[id][:hits] += 1
      end

      stats[id][:respect] += attack.respect_gain || 0
      stats[id][:warlord_hits] += 1 if attack.used_warlord?
      stats[id][:overseas_hits] += 1 if attack.overseas?
      stats[id][:total_ff] += ff

      if ff < 1.25
        stats[id][:ff_low] += 1
      elsif ff < 1.75
        stats[id][:ff_mid] += 1
      else
        stats[id][:ff_high] += 1
      end
    end

    total_actions = ->(s) { s[:hits] + s[:assists] }

    stats.values.each do |s|
      actions = total_actions.call(s)
      s[:avg_respect] = actions > 0 ? (s[:respect] / actions).round(2) : 0
      s[:avg_ff] = actions > 0 ? (s[:total_ff] / actions).round(2) : 0
    end

    stats.values.sort_by { |s| -s[:respect] }
  end
end
