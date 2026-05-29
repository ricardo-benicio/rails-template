module.exports = {
  apps: [
    {
      name: 'rails-template-3000',
      cwd: '/home/ricardo/vscode/rails-template',
      script: 'bin/rails',
      args: 'server -p 3000',
      interpreter: 'ruby',
      env: {
        RAILS_ENV: 'development',
        PORT: '3000'
      }
    },
    {
      name: 'rails-template-sidekiq',
      cwd: '/home/ricardo/vscode/rails-template',
      script: 'bundle',
      args: 'exec sidekiq -C config/sidekiq.yml',
      interpreter: 'none',
      env: {
        RAILS_ENV: 'development'
      }
    }
  ]
}
