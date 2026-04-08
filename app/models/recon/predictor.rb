require "onnxruntime"

class Recon::Predictor
  MODEL_PATH = Rails.root.join("lib/recon/model.onnx")

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

  def initialize
    raise "Model not found at #{MODEL_PATH}. Run: rake recon:train" unless MODEL_PATH.exist?

    @model = OnnxRuntime::Model.new(MODEL_PATH.to_s)
  end

  def predict(features)
    input = FEATURE_ORDER.map do |f|
      val = (features[f] || 0).to_f
      LOG_FEATURES.include?(f) ? Math.log1p([ val, 0 ].max) : val
    end
    log_prediction = @model.predict({ "features" => [input] }).values.first.flatten.first
    Math.expm1(log_prediction).round.to_i.clamp(0..)
  end

  def self.trained?
    MODEL_PATH.exist?
  end
end
