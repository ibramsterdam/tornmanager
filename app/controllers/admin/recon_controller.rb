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
      queued = 0

      rows.each do |row|
        Recon::CollectTrainingSampleJob.set(wait: (queued * seconds_per_job).seconds).perform_later(
          player_id: row.player_id,
          strength: row.strength,
          defense: row.defense,
          speed: row.speed,
          dexterity: row.dexterity,
          spied_at: row.spied_at.to_s
        )
        queued += 1
      end

      estimated_seconds = queued * seconds_per_job
      estimated_minutes = (estimated_seconds / 60.0).ceil

      Rails.cache.write("recon:import_ends_at", Time.current + estimated_seconds.seconds, expires_in: estimated_seconds.seconds)

      redirect_to admin_recon_path, notice: "Queued #{queued} training samples. ~#{queued * 3} API calls, ~#{estimated_minutes} min."
    end
  end
end
