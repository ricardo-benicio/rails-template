# Production Procfile
# Used by Kamal and other deployment platforms

web: bundle exec puma -C config/puma.rb
jobs: bundle exec sidekiq -C config/sidekiq.yml
release: bin/rails db:migrate
