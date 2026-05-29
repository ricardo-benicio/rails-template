---
name: rails-tdd
description: >
  Test-Driven Development workflow for Ruby on Rails using RSpec, FactoryBot,
  Shoulda Matchers, and Capybara. Covers unit tests, request specs, system tests,
  and the full RED → GREEN → REFACTOR cycle for Rails projects.
tags: [ruby, rails, rspec, tdd, testing, factorybot, capybara]
version: "1.0.0"
---

# Rails TDD Workflow

## The Cycle

```
RED   → Write a failing test that describes the behaviour you want
GREEN → Write the minimum code to make it pass
REFACTOR → Clean up — tests must still pass
```

Never write production code without a failing test first.

---

## Setup

```ruby
# Gemfile (test/development group)
group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webmock"
  gem "vcr"
  gem "simplecov"
end
```

```ruby
# spec/rails_helper.rb
require "spec_helper"
require "simplecov"
SimpleCov.start "rails" do
  minimum_coverage 80
end

require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
require "capybara/rails"

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.use_transactional_fixtures = true

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate { |with| with.test_framework(:rspec).and.library(:rails) }
end
```

---

## Model Specs

Test validations, associations, scopes, and instance methods.

```ruby
# spec/models/post_spec.rb
RSpec.describe Post, type: :model do
  # Associations
  it { is_expected.to belong_to(:author).class_name("User") }
  it { is_expected.to have_many(:comments).dependent(:destroy) }
  it { is_expected.to have_many(:tags).through(:post_tags) }

  # Validations
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_length_of(:title).is_at_most(255) }
  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to validate_inclusion_of(:status).in_array(%w[draft published archived]) }

  # Scopes
  describe ".published" do
    it "returns only published posts" do
      published = create(:post, status: "published")
      create(:post, status: "draft")

      expect(Post.published).to contain_exactly(published)
    end
  end

  describe ".recent" do
    it "orders by created_at descending" do
      older = create(:post, created_at: 2.days.ago)
      newer = create(:post, created_at: 1.day.ago)

      expect(Post.recent).to eq([newer, older])
    end
  end

  # Instance methods
  describe "#publish!" do
    let(:post) { create(:post, :draft) }

    it "changes status to published" do
      expect { post.publish! }.to change { post.status }.from("draft").to("published")
    end

    it "records published_at timestamp" do
      freeze_time do
        post.publish!
        expect(post.published_at).to eq(Time.current)
      end
    end
  end
end
```

---

## Factories

```ruby
# spec/factories/posts.rb
FactoryBot.define do
  factory :post do
    title  { Faker::Lorem.sentence(word_count: 4) }
    body   { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    status { "draft" }
    association :author, factory: :user

    trait :published do
      status       { "published" }
      published_at { Time.current }
    end

    trait :archived do
      status { "archived" }
    end

    trait :with_comments do
      after(:create) do |post|
        create_list(:comment, 3, post: post)
      end
    end

    trait :with_tags do
      after(:create) do |post|
        post.tags = create_list(:tag, 2)
      end
    end
  end
end

# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name     { Faker::Name.full_name }
    email    { Faker::Internet.unique.email }
    password { "password123" }

    trait :admin do
      role { "admin" }
    end
  end
end
```

---

## Service Object Specs

```ruby
# spec/services/posts/create_service_spec.rb
RSpec.describe Posts::CreateService do
  subject(:result) { described_class.call(user, params) }

  let(:user)   { create(:user) }
  let(:params) { { title: "My Post", body: "Content here", status: "draft" } }

  context "with valid params" do
    it "returns a successful result" do
      expect(result).to be_success
    end

    it "creates a post" do
      expect { result }.to change(Post, :count).by(1)
    end

    it "assigns the author" do
      expect(result.post.author).to eq(user)
    end

    it "enqueues a PostCreatedJob" do
      expect { result }.to have_enqueued_job(PostCreatedJob)
    end
  end

  context "with invalid params" do
    let(:params) { { title: "", body: "Content" } }

    it "returns a failed result" do
      expect(result).not_to be_success
    end

    it "does not create a post" do
      expect { result }.not_to change(Post, :count)
    end

    it "returns error messages" do
      expect(result.errors).to include("Title can't be blank")
    end
  end
end
```

---

## Request Specs (API)

Test HTTP layer end-to-end, without mocking controllers.

```ruby
# spec/requests/api/v1/posts_spec.rb
RSpec.describe "Api::V1::Posts", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }  # helper that returns JWT/session headers

  describe "GET /api/v1/posts" do
    before { create_list(:post, 3, :published) }

    it "returns 200 with posts array" do
      get "/api/v1/posts", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(3)
    end

    it "returns 401 without authentication" do
      get "/api/v1/posts"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/posts" do
    let(:valid_params) do
      { post: { title: "New Post", body: "Body content", status: "draft" } }
    end

    it "creates a post and returns 201" do
      expect {
        post "/api/v1/posts", params: valid_params, headers: headers
      }.to change(Post, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "returns 422 with invalid params" do
      post "/api/v1/posts",
           params: { post: { title: "" } },
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["errors"]).to be_present
    end
  end
end
```

---

## Job Specs

```ruby
# spec/jobs/post_created_job_spec.rb
RSpec.describe PostCreatedJob, type: :job do
  let(:post) { create(:post) }

  it "sends notification email" do
    expect(PostMailer).to receive(:new_post_notification).with(post).and_call_original
    described_class.perform_now(post.id)
  end

  it "retries on network timeout" do
    expect(described_class.retry_on_options).to include(Net::OpenTimeout)
  end

  it "discards on missing record" do
    expect { described_class.perform_now(SecureRandom.uuid) }.not_to raise_error
  end
end
```

---

## System Tests (Capybara)

Test full user flows through the browser.

```ruby
# spec/system/creating_a_post_spec.rb
RSpec.describe "Creating a post", type: :system do
  let(:user) { create(:user) }

  before { sign_in user }

  it "allows a user to create a draft post" do
    visit new_post_path

    fill_in "Title", with: "My First Post"
    fill_in "Body",  with: "This is the content of my post."
    select  "Draft", from: "Status"

    click_button "Save Post"

    expect(page).to have_text("Post was successfully created.")
    expect(page).to have_text("My First Post")
  end

  it "shows validation errors for missing title" do
    visit new_post_path
    fill_in "Body", with: "Content"
    click_button "Save Post"

    expect(page).to have_text("Title can't be blank")
  end
end
```

---

## Test Helpers

```ruby
# spec/support/helpers/auth_helpers.rb
module AuthHelpers
  def auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end

  def sign_in(user)
    post "/users/sign_in", params: { user: { email: user.email, password: "password123" } }
  end
end

# spec/support/helpers/json_helpers.rb
module JsonHelpers
  def json_body
    JSON.parse(response.body)
  end
end

# spec/rails_helper.rb — include helpers:
# config.include AuthHelpers, type: :request
# config.include JsonHelpers,  type: :request
```

---

## Coverage Enforcement

```ruby
# spec/spec_helper.rb
require "simplecov"
SimpleCov.start "rails" do
  minimum_coverage 80
  add_filter "/spec/"
  add_filter "/config/"
  add_group "Services",    "app/services"
  add_group "Serializers", "app/serializers"
  add_group "Jobs",        "app/jobs"
end
```

Run with: `bundle exec rspec --format progress`
Coverage report: `open coverage/index.html`

---

## TDD Decision Guide

| What to test | Spec type |
|---|---|
| Model validations, scopes, methods | `spec/models/` |
| Service object business logic | `spec/services/` |
| API endpoints (HTTP status, body) | `spec/requests/` |
| Background job execution | `spec/jobs/` |
| User flows through UI | `spec/system/` |
| Mailers | `spec/mailers/` |
| Routing | `spec/routing/` (rare — prefer request specs) |
