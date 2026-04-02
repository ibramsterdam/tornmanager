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

      existing_ends_at = Rails.cache.read("recon:import_ends_at")
      queue_starts_at = if existing_ends_at.present? && existing_ends_at > Time.current
        existing_ends_at
      else
        Time.current
      end

      queued = 0
      skipped = 0
      rows.each do |row|
        sample = Recon::TrainingSample.find_or_initialize_by(player_id: row.player_id, spied_at: row.spied_at)

        if sample.persisted? && sample.level.present?
          skipped += 1
          next
        end

        sample.update!(
          strength: row.strength,
          defense: row.defense,
          speed: row.speed,
          dexterity: row.dexterity
        )

        Recon::CollectTrainingSampleJob.set(wait_until: queue_starts_at + (queued * seconds_per_job).seconds).perform_later(
          player_id: row.player_id,
          spied_at: row.spied_at.to_s
        )
        queued += 1
      end

      if queued > 0
        new_ends_at = queue_starts_at + (queued * seconds_per_job).seconds
        remaining_seconds = (new_ends_at - Time.current).to_i

        Rails.cache.write("recon:import_ends_at", new_ends_at, expires_in: remaining_seconds.seconds)
      end

      skip_msg = skipped > 0 ? " #{skipped} already collected." : ""
      if queued > 0
        redirect_to admin_recon_path, notice: "Queued #{queued} training samples.#{skip_msg} ~#{queued * 3} API calls, ~#{((queued * seconds_per_job) / 60.0).ceil} min."
      else
        redirect_to admin_recon_path, notice: "All #{skipped} samples already collected. Nothing to queue."
      end
    end
  end
end
