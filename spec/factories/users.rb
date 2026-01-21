# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    confirmed_at { Time.current }
    role { :user }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :manager do
      role { :manager }
    end

    trait :admin do
      role { :admin }
    end

    trait :locked do
      locked_at { Time.current }
      failed_attempts { 5 }
    end
  end
end
