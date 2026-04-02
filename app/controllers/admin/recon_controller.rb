module Admin
  class ReconController < ApplicationController
    before_action :require_admin

    def show
      @training_sample_count = Recon::TrainingSample.count
      @latest_sample = Recon::TrainingSample.order(created_at: :desc).first
      @samples = Recon::TrainingSample.order(created_at: :desc).limit(100)
      @import_ends_at = Rails.cache.read("recon:import_ends_at")
      @import_in_progress = @import_ends_at.present? && @import_ends_at > Time.current
    end

    def import
      raw_data = params[:spy_data]

      if raw_data.blank?
        return redirect_to admin_recon_path, alert: "No data provided."
      end

      rows = Recon::SpyDataParser.parse(raw_data)

      if rows.empty?
        return redirect_to admin_recon_path, alert: "Could not parse any rows. Check the format."
      end

      seconds_per_job = 9 # 3 API calls/job, ~20 calls/min max

      # Start new jobs after any existing queue finishes
      existing_ends_at = Rails.cache.read("recon:import_ends_at")
      queue_starts_at = if existing_ends_at.present? && existing_ends_at > Time.current
        existing_ends_at
      else
        Time.current
      end

      queued = 0
      rows.each do |row|
        Recon::CollectTrainingSampleJob.set(wait_until: queue_starts_at + (queued * seconds_per_job).seconds).perform_later(
          player_id: row.player_id,
          strength: row.strength,
          defense: row.defense,
          speed: row.speed,
          dexterity: row.dexterity,
          spied_at: row.spied_at.to_s
        )
        queued += 1
      end

      new_ends_at = queue_starts_at + (queued * seconds_per_job).seconds
      remaining_seconds = (new_ends_at - Time.current).to_i

      Rails.cache.write("recon:import_ends_at", new_ends_at, expires_in: remaining_seconds.seconds)

      redirect_to admin_recon_path, notice: "Queued #{queued} training samples. ~#{queued * 3} API calls, ~#{(remaining_seconds / 60.0).ceil} min total."
    end
  end
end
