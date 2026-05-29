# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject(:policy) { described_class.new(current_user, target_user) }

  let(:target_user) { create(:user) }

  context 'as the user themselves' do
    let(:current_user) { target_user }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:update) }
  end

  context 'as a different regular user' do
    let(:current_user) { create(:user) }

    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:update) }
  end

  context 'as an admin' do
    let(:current_user) { create(:user, :admin) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:update) }
  end
end
