# frozen_string_literal: true

# =============================================================================
# Seeds
# =============================================================================
# This file should ensure the existence of records required to run the
# application in every environment (production, development, test).
#
# The code here should be idempotent so that it can be executed at any point
# in every environment.
#
# Run with: bin/rails db:seed
# =============================================================================

puts "Seeding database..."

# =============================================================================
# Admin User
# =============================================================================
# Create default admin user for all environments

admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "password123")

admin = User.find_or_initialize_by(email: admin_email)
admin.assign_attributes(
  first_name: "Admin",
  last_name: "User",
  password: admin_password,
  password_confirmation: admin_password,
  role: :admin,
  confirmed_at: Time.current
)

if admin.new_record?
  admin.save!
  puts "  Created admin user: #{admin_email}"
else
  puts "  Admin user already exists: #{admin_email}"
end

# =============================================================================
# Development Seeds
# =============================================================================
if Rails.env.development?
  puts "\nSeeding development data..."

  # ---------------------------------------------------------------------------
  # Sample Users
  # ---------------------------------------------------------------------------
  puts "  Creating sample users..."

  users_data = [
    { first_name: "John", last_name: "Doe", email: "john@example.com", role: :user },
    { first_name: "Jane", last_name: "Smith", email: "jane@example.com", role: :user },
    { first_name: "Bob", last_name: "Manager", email: "bob@example.com", role: :manager },
    { first_name: "Alice", last_name: "Admin", email: "alice@example.com", role: :admin }
  ]

  users_data.each do |user_attrs|
    user = User.find_or_initialize_by(email: user_attrs[:email])
    user.assign_attributes(
      **user_attrs,
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    if user.new_record?
      user.save!
      puts "    Created: #{user.full_name} (#{user.email}) - #{user.role}"
    else
      puts "    Exists: #{user.full_name} (#{user.email}) - #{user.role}"
    end
  end

  # ---------------------------------------------------------------------------
  # Random Users (for pagination testing)
  # ---------------------------------------------------------------------------
  random_users_count = 20
  existing_random_users = User.where("email LIKE ?", "user%@example.com").count
  users_to_create = random_users_count - existing_random_users

  if users_to_create.positive?
    puts "  Creating #{users_to_create} random users..."

    users_to_create.times do |i|
      index = existing_random_users + i + 1
      User.create!(
        first_name: "User",
        last_name: "#{index.to_s.rjust(3, '0')}",
        email: "user#{index}@example.com",
        password: "password123",
        password_confirmation: "password123",
        role: :user,
        confirmed_at: Time.current
      )
    end

    puts "    Created #{users_to_create} random users"
  else
    puts "  Random users already exist"
  end

  # ---------------------------------------------------------------------------
  # Unconfirmed User (for testing confirmation flow)
  # ---------------------------------------------------------------------------
  unconfirmed_email = "unconfirmed@example.com"
  unconfirmed = User.find_or_initialize_by(email: unconfirmed_email)
  unconfirmed.assign_attributes(
    first_name: "Unconfirmed",
    last_name: "User",
    password: "password123",
    password_confirmation: "password123",
    role: :user,
    confirmed_at: nil
  )

  if unconfirmed.new_record?
    unconfirmed.save!
    puts "  Created unconfirmed user: #{unconfirmed_email}"
  else
    puts "  Unconfirmed user already exists: #{unconfirmed_email}"
  end

  # ---------------------------------------------------------------------------
  # Locked User (for testing lockout flow)
  # ---------------------------------------------------------------------------
  locked_email = "locked@example.com"
  locked = User.find_or_initialize_by(email: locked_email)
  locked.assign_attributes(
    first_name: "Locked",
    last_name: "User",
    password: "password123",
    password_confirmation: "password123",
    role: :user,
    confirmed_at: Time.current,
    locked_at: Time.current,
    failed_attempts: 5
  )

  if locked.new_record?
    locked.save!
    puts "  Created locked user: #{locked_email}"
  else
    puts "  Locked user already exists: #{locked_email}"
  end

  # ---------------------------------------------------------------------------
  # Summary
  # ---------------------------------------------------------------------------
  puts "\n" + "=" * 50
  puts "Development seed complete!"
  puts "=" * 50
  puts "Total users: #{User.with_discarded.count}"
  puts "  - Admins: #{User.with_discarded.admin.count}"
  puts "  - Managers: #{User.with_discarded.manager.count}"
  puts "  - Users: #{User.with_discarded.user.count}"
  puts "\nLogin credentials:"
  puts "  Admin: #{admin_email} / #{admin_password}"
  puts "  User: john@example.com / password123"
  puts "  Manager: bob@example.com / password123"
end

puts "\nSeeding complete!"
