module Admin
  class ReconController < ApplicationController
    before_action :require_admin

    def show
      @training_sample_count = Recon::TrainingSample.count
      @latest_sample = Recon::TrainingSample.order(created_at: :desc).first
      @samples = Recon::TrainingSample.order(created_at: :desc).limit(100)
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
      skipped = 0
      queued = 0

      rows.each do |row|
        if Recon::TrainingSample.exists?(player_id: row.player_id, spied_at: row.spied_at&.beginning_of_day)
          skipped += 1
          next
        end

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

      estimated_minutes = (queued * seconds_per_job / 60.0).ceil

      redirect_to admin_recon_path, notice: "Queued #{queued} training samples (#{skipped} duplicates skipped). ~#{queued * 3} API calls, ~#{estimated_minutes} min."
    end
  end
end
