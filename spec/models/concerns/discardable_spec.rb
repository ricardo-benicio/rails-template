# frozen_string_literal: true

require "rails_helper"

RSpec.describe Discardable do
  describe "User with Discardable" do
    let!(:active_user) { create(:user) }
    let!(:discarded_user) { create(:user).tap(&:discard) }

    describe "default scope" do
      it "excludes discarded records by default" do
        expect(User.all).to include(active_user)
        expect(User.all).not_to include(discarded_user)
      end
    end

    describe ".with_discarded" do
      it "includes all records" do
        expect(User.with_discarded).to include(active_user)
        expect(User.with_discarded).to include(discarded_user)
      end
    end

    describe ".only_discarded" do
      it "returns only discarded records" do
        expect(User.only_discarded).not_to include(active_user)
        expect(User.only_discarded).to include(discarded_user)
      end
    end

    describe ".kept" do
      it "returns only non-discarded records" do
        expect(User.kept).to include(active_user)
        expect(User.kept).not_to include(discarded_user)
      end
    end

    describe "#discard" do
      it "sets discarded_at timestamp" do
        expect { active_user.discard }.to change { active_user.discarded_at }.from(nil)
      end

      it "marks record as discarded" do
        active_user.discard
        expect(active_user).to be_discarded
      end
    end

    describe "#undiscard" do
      it "clears discarded_at timestamp" do
        expect { discarded_user.undiscard }.to change { discarded_user.discarded_at }.to(nil)
      end

      it "marks record as not discarded" do
        discarded_user.undiscard
        expect(discarded_user).not_to be_discarded
      end
    end

    describe "#discarded?" do
      it "returns true for discarded records" do
        expect(discarded_user).to be_discarded
      end

      it "returns false for active records" do
        expect(active_user).not_to be_discarded
      end
    end
  end
end
