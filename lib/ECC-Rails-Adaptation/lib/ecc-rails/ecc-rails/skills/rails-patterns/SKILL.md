---
name: rails-patterns
description: >
  Ruby on Rails architecture patterns, conventions, and ecosystem best practices.
  Covers ActiveRecord, service objects, concerns, background jobs, API design,
  Hotwire/Turbo, and production-ready Rails application structure.
tags: [ruby, rails, activerecord, api, hotwire, sidekiq, backend]
version: "1.0.0"
---

# Rails Patterns

## Core Philosophy

Rails is an opinionated framework — follow **Convention over Configuration**.
Lean into Rails idioms rather than fighting them. Use the framework's built-in
abstractions before reaching for custom solutions.

---

## Project Structure

```
app/
├── controllers/          # Thin controllers — only request/response logic
├── models/               # ActiveRecord models — validations, associations, scopes
├── services/             # Business logic (plain Ruby objects)
├── queries/              # Complex ActiveRecord query objects
├── jobs/                 # Background jobs (Sidekiq / GoodJob)
├── mailers/              # ActionMailer
├── serializers/          # API serialization (ActiveModelSerializers / Blueprinter)
├── policies/             # Authorization (Pundit)
├── forms/                # Form objects for complex multi-model forms
└── presenters/           # View-layer logic (avoid helpers bloat)
config/
├── routes.rb             # Resourceful routing, namespaces, constraints
└── initializers/         # Third-party setup
```

---

## Models

### Keep models lean — use concerns for shared behaviour

```ruby
# app/models/concerns/trackable.rb
module Trackable
  extend ActiveSupport::Concern

  included do
    belongs_to :created_by, class_name: "User"
    belongs_to :updated_by, class_name: "User", optional: true

    before_create { self.created_by = Current.user }
    before_update { self.updated_by = Current.user }
  end
end

# app/models/post.rb
class Post < ApplicationRecord
  include Trackable
  include Searchable

  # Associations
  belongs_to :author, class_name: "User"
  has_many   :comments, dependent: :destroy
  has_many   :tags, through: :post_tags

  # Validations
  validates :title,   presence: true, length: { maximum: 255 }
  validates :body,    presence: true
  validates :status,  inclusion: { in: %w[draft published archived] }

  # Scopes — always return ActiveRecord::Relation
  scope :published,  -> { where(status: "published") }
  scope :recent,     -> { order(created_at: :desc) }
  scope :by_author,  ->(user) { where(author: user) }

  # Enums (Rails 7+)
  enum :status, { draft: 0, published: 1, archived: 2 }, prefix: true

  # Callbacks — use sparingly, prefer service objects for side effects
  after_commit :notify_subscribers, on: :create
end
```

### Query objects for complex queries

```ruby
# app/queries/posts_query.rb
class PostsQuery
  def initialize(relation = Post.all)
    @relation = relation
  end

  def call(filters = {})
    result = @relation
    result = result.by_author(filters[:author_id]) if filters[:author_id]
    result = result.where("title ILIKE ?", "%#{filters[:search]}%") if filters[:search]
    result = result.where(created_at: filters[:from]..) if filters[:from]
    result.published.recent
  end
end

# Usage in controller:
# PostsQuery.new.call(search: params[:q], author_id: params[:author_id])
```

---

## Controllers

### Keep controllers thin — delegate to service objects

```ruby
# app/controllers/api/v1/posts_controller.rb
module Api
  module V1
    class PostsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_post, only: [:show, :update, :destroy]

      def index
        posts = PostsQuery.new.call(index_params)
        render json: PostSerializer.new(posts).serializable_hash
      end

      def create
        result = Posts::CreateService.call(current_user, post_params)

        if result.success?
          render json: PostSerializer.new(result.post).serializable_hash,
                 status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_post
        @post = Post.find(params[:id])
        authorize @post  # Pundit
      end

      def post_params
        params.require(:post).permit(:title, :body, :status, tag_ids: [])
      end

      def index_params
        params.permit(:search, :author_id, :from, :page, :per_page)
      end
    end
  end
end
```

---

## Service Objects

Business logic belongs in service objects, not models or controllers.

```ruby
# app/services/posts/create_service.rb
module Posts
  class CreateService
    Result = Struct.new(:success?, :post, :errors, keyword_init: true)

    def self.call(user, params)
      new(user, params).call
    end

    def initialize(user, params)
      @user   = user
      @params = params
    end

    def call
      post = Post.new(@params.merge(author: @user))

      if post.save
        PostCreatedJob.perform_later(post.id)
        Result.new(success?: true, post: post, errors: [])
      else
        Result.new(success?: false, post: post, errors: post.errors.full_messages)
      end
    end
  end
end
```

---

## Background Jobs

```ruby
# app/jobs/post_created_job.rb
class PostCreatedJob < ApplicationJob
  queue_as :default
  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(post_id)
    post = Post.find(post_id)
    PostMailer.new_post_notification(post).deliver_now
    SearchIndexService.call(post)
  end
end
```

---

## API Serialization

Use Blueprinter or ActiveModelSerializers for consistent API responses.

```ruby
# app/serializers/post_serializer.rb
class PostSerializer
  include JSONAPI::Serializer

  attributes :id, :title, :body, :status, :created_at

  attribute :author do |post|
    { id: post.author.id, name: post.author.full_name }
  end

  attribute :tags do |post|
    post.tags.map { |t| { id: t.id, name: t.name } }
  end
end
```

---

## Routing

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # API namespace with versioning
  namespace :api do
    namespace :v1 do
      resources :posts do
        resources :comments, only: [:index, :create, :destroy]
        member do
          patch :publish
          patch :archive
        end
        collection do
          get :search
        end
      end
      resources :users, only: [:show, :update]
    end
  end

  # Hotwire / Turbo routes
  resources :posts do
    resources :comments, only: [:create, :destroy]
  end

  # Health check (for load balancers)
  get "/health", to: proc { [200, {}, ["ok"]] }
end
```

---

## Database & Migrations

```ruby
# db/migrate/20240101000000_create_posts.rb
class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts, id: :uuid do |t|
      t.string      :title,    null: false
      t.text        :body,     null: false
      t.integer     :status,   null: false, default: 0
      t.references  :author,   null: false, foreign_key: { to_table: :users }, type: :uuid
      t.timestamps
    end

    add_index :posts, :status
    add_index :posts, :created_at
    add_index :posts, [:author_id, :status]
  end
end
```

**Migration rules:**
- Always use `null: false` explicitly
- Add indexes for all foreign keys and filter columns
- Use UUIDs for public-facing IDs
- Never use `change_column` on production data without a safe migration strategy
- Use `strong_migrations` gem to catch dangerous migrations

---

## Hotwire / Turbo (full-stack Rails)

```ruby
# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  def create
    @comment = @post.comments.build(comment_params.merge(author: current_user))

    if @comment.save
      respond_to do |format|
        format.turbo_stream  # renders app/views/comments/create.turbo_stream.erb
        format.html { redirect_to @post }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

```erb
<%# app/views/comments/create.turbo_stream.erb %>
<%= turbo_stream.append "comments" do %>
  <%= render @comment %>
<% end %>
<%= turbo_stream.replace "comment-form" do %>
  <%= render "form", post: @post, comment: Comment.new %>
<% end %>
```

---

## Configuration & Environment

```ruby
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL") }
end

# Never hardcode secrets — always ENV
# Use Rails credentials for structured secrets:
# rails credentials:edit
# database:
#   password: <%= Rails.application.credentials.database.password %>
```

---

## Key Gems Ecosystem

| Purpose | Gem |
|---|---|
| Auth | `devise` / `rodauth` |
| Authorization | `pundit` / `action_policy` |
| Background jobs | `sidekiq` / `good_job` |
| API serialization | `jsonapi-serializer` / `blueprinter` |
| Safe migrations | `strong_migrations` |
| Pagination | `pagy` |
| File uploads | `active_storage` + `shrine` |
| Search | `pg_search` / `elasticsearch-rails` |
| Caching | `redis-rails` |
| Feature flags | `flipper` |
| Observability | `opentelemetry-rails` |
