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

    def stats
      @clip_pct = (params[:clip] || 1).to_f.clamp(0, 10)
      all_samples = Recon::TrainingSample.where.not(xantaken: nil)
      @total = all_samples.count
      return if @total == 0

      @complete_samples = @total
      @incomplete_samples = Recon::TrainingSample.where(xantaken: nil).count

      # Remove outliers based on total_stats percentile
      if @clip_pct > 0
        totals = all_samples.pluck(Arel.sql("strength + defense + speed + dexterity")).sort
        lower = totals[(totals.size * @clip_pct / 100).to_i]
        upper = totals[(totals.size * (100 - @clip_pct) / 100).to_i]
        samples = all_samples.where("(strength + defense + speed + dexterity) BETWEEN ? AND ?", lower, upper)
        @clipped_count = @total - samples.count
      else
        samples = all_samples
        @clipped_count = 0
      end

      @sample_count = samples.count
      all_columns = Recon::TrainingSample::FEATURE_COLUMNS + Recon::TrainingSample::LABEL_COLUMNS

      @distributions = {}
      @warnings = []

      all_columns.each do |col|
        values = samples.pluck(col).compact
        next if values.empty?

        d = compute_distribution(col, values)
        @distributions[col] = d

        if d[:zero_pct] > 70
          @warnings << { feature: col, type: :high_zeros, message: "#{d[:zero_pct]}% zeros - consider binary encoding (0 vs >0)" }
        elsif d[:zero_pct] > 30
          @warnings << { feature: col, type: :moderate_zeros, message: "#{d[:zero_pct]}% zeros - may reduce predictive power" }
        end

        if d[:std] < 1 || (d[:p25] == d[:p75] && d[:p25] == d[:median])
          @warnings << { feature: col, type: :low_variance, message: "Near-zero variance - consider dropping" }
        end

        skewness = d[:mean] > 0 ? (d[:mean] - d[:median]).abs / [ d[:std], 1 ].max : 0
        if skewness > 1 && d[:max] > d[:p75] * 10
          @warnings << { feature: col, type: :skewed, message: "Heavily right-skewed - consider log transform" }
        end
      end

      @warnings.sort_by! { |w| { high_zeros: 0, low_variance: 1, skewed: 2, moderate_zeros: 3 }[w[:type]] }

      total_stats = samples.pluck(Arel.sql("strength + defense + speed + dexterity")).compact.sort
      @total_stats_dist = compute_distribution("total_stats", total_stats)

      # Compute normal curve overlay
      mean = @total_stats_dist[:mean]
      std = [ @total_stats_dist[:std], 1 ].max
      bin_min = @total_stats_dist[:bin_min]
      bin_width = @total_stats_dist[:bin_width]
      @normal_curve = (0...20).map do |i|
        x = bin_min + (i + 0.5) * bin_width
        y = Math.exp(-0.5 * ((x - mean) / std)**2)
        y
      end
      normal_max = @normal_curve.max || 1
      hist_max = @total_stats_dist[:histogram].max || 1
      @normal_curve = @normal_curve.map { |y| (y / normal_max * hist_max).round(1) }
    end

    private

    def import_rows(rows)
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
        if Recon::TrainingSample.exists?(player_id: row.player_id, spied_at: row.spied_at)
          skipped += 1
          next
        end

        Recon::TrainingSample.create!(
          player_id: row.player_id,
          strength: row.strength,
          defense: row.defense,
          speed: row.speed,
          dexterity: row.dexterity,
          spied_at: row.spied_at
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

    def fetch_personalstats_for_predict(api_key, torn_id)
      batches = Recon::FeatureSet::API_STAT_NAMES.each_slice(10).to_a
      batches.reduce({}) do |result, batch|
        stats = Recon::TornApi::PersonalStats.new(api_key, torn_id, stats: batch, timestamp: Time.now.to_i).fetch
        result.merge(stats)
      end
    end

    def compute_distribution(col, values)
      sorted = values.sort
      count = sorted.size
      mean = sorted.sum.to_f / count
      median = count.odd? ? sorted[count / 2] : (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
      min = sorted.first
      max = sorted.last
      std = Math.sqrt(sorted.sum { |v| (v - mean)**2 } / count)
      p25 = sorted[(count * 0.25).to_i]
      p75 = sorted[(count * 0.75).to_i]
      zeros = sorted.count(0)

      bins = 20
      bin_width = max > min ? (max - min).to_f / bins : 1
      histogram = Array.new(bins, 0)
      sorted.each do |v|
        bin = [ ((v - min) / bin_width).to_i, bins - 1 ].min
        histogram[bin] += 1
      end

      {
        count: count, mean: mean.round(1), median: median.round(1),
        min: min, max: max, std: std.round(1),
        p25: p25, p75: p75, zeros: zeros,
        zero_pct: (zeros * 100.0 / count).round(1),
        histogram: histogram,
        bin_width: bin_width.round(1), bin_min: min
      }
    end

    public

    def predict
      torn_id = params[:torn_id].to_s.strip
      if torn_id.blank?
        return render turbo_stream: turbo_stream.replace("predict-result",
          partial: "admin/recon/predict_result", locals: { error: "Please enter a Torn ID." })
      end

      api_key = AdminCredentials.api_key
      unless api_key
        return render turbo_stream: turbo_stream.replace("predict-result",
          partial: "admin/recon/predict_result", locals: { error: "Admin API key not configured." })
      end

      unless Recon::Predictor.trained?
        return render turbo_stream: turbo_stream.replace("predict-result",
          partial: "admin/recon/predict_result", locals: { error: "Model not trained. Run: rake recon:train" })
      end

      personalstats = fetch_personalstats_for_predict(api_key, torn_id)
      profile = Recon::TornApi::Profile.new(api_key, torn_id).fetch
      features = Recon::FeatureSet.build(personalstats: personalstats, profile: profile)

      predictor = Recon::Predictor.new
      prediction = predictor.predict(features)

      render turbo_stream: turbo_stream.replace("predict-result",
        partial: "admin/recon/predict_result",
        locals: { prediction: prediction, torn_id: torn_id, features: features, profile: profile, error: nil })
    rescue TornApi::ApiError, TornApi::InvalidKeyError, TornApi::NotFoundError => e
      render turbo_stream: turbo_stream.replace("predict-result",
        partial: "admin/recon/predict_result", locals: { error: "API error: #{e.message}" })
    end

    def quick_add
      torn_id = params[:torn_id].to_s.strip
      strength = params[:strength].to_s.gsub(/[^0-9]/, "").to_i
      defense = params[:defense].to_s.gsub(/[^0-9]/, "").to_i
      speed = params[:speed].to_s.gsub(/[^0-9]/, "").to_i
      dexterity = params[:dexterity].to_s.gsub(/[^0-9]/, "").to_i

      if torn_id.blank? || (strength + defense + speed + dexterity) == 0
        return redirect_to admin_recon_path, alert: "Torn ID and at least one stat are required."
      end

      spied_at = Date.current

      sample = Recon::TrainingSample.find_or_initialize_by(player_id: torn_id, spied_at: spied_at)
      sample.update!(strength: strength, defense: defense, speed: speed, dexterity: dexterity)

      Recon::CollectTrainingSampleJob.perform_later(player_id: torn_id.to_i, spied_at: spied_at.to_s)

      total = ActiveSupport::NumberHelper.number_to_delimited(strength + defense + speed + dexterity)
      redirect_to admin_recon_path, notice: "Added sample for #{torn_id} (#{total} total). Collecting personalstats..."
    end

    def import_file
      file = params[:file]
      unless file.present?
        return redirect_to admin_recon_path, alert: "Please select a file to upload."
      end

      content = file.read.force_encoding("UTF-8")
      rows = Recon::SpyDataParser.parse_jsonl(content)

      if rows.empty?
        return redirect_to admin_recon_path, alert: "Could not parse any rows. Check the file format."
      end

      import_rows(rows)
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

      import_rows(rows)
    end
  end
end
