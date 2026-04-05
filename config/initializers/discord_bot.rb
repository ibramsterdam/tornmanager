Rails.application.config.after_initialize do
  Rails.error.subscribe(Discord::ErrorNotifier.new)
end
