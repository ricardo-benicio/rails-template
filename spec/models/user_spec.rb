# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_length_of(:first_name).is_at_most(50) }
    it { is_expected.to validate_length_of(:last_name).is_at_most(50) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    it { is_expected.to define_enum_for(:role).with_values(user: 0, manager: 1, admin: 2) }
  end

  describe "Devise modules" do
    it { is_expected.to respond_to(:valid_password?) }
    it { is_expected.to respond_to(:reset_password!) }
    it { is_expected.to respond_to(:send_confirmation_instructions) }
    it { is_expected.to respond_to(:lock_access!) }
  end

  describe "#full_name" do
    it "returns first and last name combined" do
      user = build(:user, first_name: "John", last_name: "Doe")
      expect(user.full_name).to eq("John Doe")
    end

    it "handles nil values" do
      user = build(:user, first_name: nil, last_name: nil)
      user.valid? # trigger validations but don't save
      expect(user.full_name).to eq("")
    end
  end

  describe "#initials" do
    it "returns initials from first and last name" do
      user = build(:user, first_name: "John", last_name: "Doe")
      expect(user.initials).to eq("JD")
    end

    it "returns uppercase initials" do
      user = build(:user, first_name: "john", last_name: "doe")
      expect(user.initials).to eq("JD")
    end
  end

  describe "roles" do
    it "defaults to user role" do
      user = create(:user)
      expect(user.role).to eq("user")
    end

    it "can be a manager" do
      user = create(:user, :manager)
      expect(user.manager?).to be true
    end

    it "can be an admin" do
      user = create(:user, :admin)
      expect(user.admin?).to be true
    end
  end

  describe "JWT" do
    it "has a jti after creation" do
      user = create(:user)
      expect(user.jti).to be_present
    end

    it "includes role in jwt_payload" do
      user = create(:user, :admin)
      payload = user.jwt_payload
      expect(payload["role"]).to eq("admin")
    end
  end

  describe "factories" do
    it "has a valid factory" do
      expect(build(:user)).to be_valid
    end

    it "creates an unconfirmed user" do
      user = create(:user, :unconfirmed)
      expect(user.confirmed_at).to be_nil
    end

    it "creates a locked user" do
      user = create(:user, :locked)
      expect(user.access_locked?).to be true
    end
  end
end
