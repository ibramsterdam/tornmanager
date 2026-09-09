class EliminationSnapshot < ApplicationRecord
  scope :latest_batch, -> { where(captured_at: maximum(:captured_at)) }

  def self.record_teams(teams, at: Time.current)
    rows = teams.map do |team|
      {
        team_torn_id: team.torn_id,
        name: team.name,
        tickets: team.tickets,
        lives: team.lives,
        wins: team.wins,
        losses: team.losses,
        position: team.position,
        eliminated: team.eliminated,
        captured_at: at,
        created_at: at,
        updated_at: at
      }
    end
    insert_all!(rows)
  end
end
