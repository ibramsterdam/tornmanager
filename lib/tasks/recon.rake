namespace :recon do
  desc "Train the recon predictor model (Python + scikit-learn → ONNX)"
  task train: :environment do
    venv_python = Rails.root.join("lib/recon/.venv/bin/python3")
    script = Rails.root.join("lib/recon/train_model.py")
    db_path = ActiveRecord::Base.connection_db_config.database
    output = Rails.root.join("lib/recon/model.onnx")

    unless venv_python.exist?
      puts "Setting up Python venv..."
      system("python3", "-m", "venv", venv_python.dirname.dirname.to_s, exception: true)
      system(venv_python.dirname.join("pip").to_s, "install", "-r",
        Rails.root.join("lib/recon/requirements.txt").to_s, exception: true)
    end

    puts "Training model..."
    system(venv_python.to_s, script.to_s, db_path.to_s, output.to_s, exception: true)
    puts "Done! Model at #{output}"
  end
end
