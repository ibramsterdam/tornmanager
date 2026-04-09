require "onnxruntime"

class Recon::Predictor
  MODEL_DIR = Rails.root.join("lib/recon")

  # Must match ALL_FEATURES order in train_model.py
  FEATURE_ORDER = (
    Recon::TrainingSample::FEATURE_COLUMNS + %w[
      xan_per_day refills_per_day edrink_per_day se_per_day
      total_energy energy_per_day boosters_per_day has_se
    ]
  ).freeze

  # Must match LOG_FEATURES in train_model.py
  LOG_FEATURES = %w[
    xantaken energydrinkused statenhancersused boostersused
    lsdtaken revives exttaken victaken rehabs
    attackswon networth hospital
    total_energy
  ].to_set.freeze

  # Must match TIERS in train_model.py
  TIERS = [
    [ :low,  0,          1e9  ],
    [ :mid,  1e9,        5e9  ],
    [ :high, 5e9,        Float::INFINITY ]
  ].freeze

  def initialize
    global_path = MODEL_DIR.join("model_global.onnx")
    raise "Global model not found at #{global_path}. Run: rake recon:train" unless global_path.exist?

    @global_model = OnnxRuntime::Model.new(global_path.to_s)

    @tier_models = {}
    TIERS.each do |name, _, _|
      path = MODEL_DIR.join("model_#{name}.onnx")
      @tier_models[name] = OnnxRuntime::Model.new(path.to_s) if path.exist?
    end
  end

  def predict(features)
    input = build_input(features)

    # First pass: global model for rough estimate to pick tier
    rough = run_model(@global_model, input)

    # Pick tier model
    tier_name = TIERS.find { |_, lo, hi| rough >= lo && rough < hi }&.first
    tier_model = @tier_models[tier_name]

    # Second pass: tier model for refined prediction (fall back to global)
    if tier_model
      run_model(tier_model, input)
    else
      rough
    end
  end

  def self.trained?
    MODEL_DIR.join("model_global.onnx").exist?
  end

  private

  def build_input(features)
    FEATURE_ORDER.map do |f|
      val = (features[f] || 0).to_f
      LOG_FEATURES.include?(f) ? Math.log1p([ val, 0 ].max) : val
    end
  end

  def run_model(model, input)
    log_prediction = model.predict({ "features" => [ input ] }).values.first.flatten.first
    Math.expm1(log_prediction).round.to_i.clamp(0..)
  end
end
