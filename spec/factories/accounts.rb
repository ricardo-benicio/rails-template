# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    association :owner, factory: :user

    trait :with_member do
      transient { member { nil } }
      after(:create) do |account, evaluator|
        create(:account_membership, account: account, user: evaluator.member, role: :member) if evaluator.member
      end
    end
  end

  factory :account_membership do
    association :account
    association :user
    role { :member }
  end
end
