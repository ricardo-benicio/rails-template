# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'PaperTrail versioning' do
    let(:user) { create(:user) }

    it 'records a create version' do
      expect(user.versions.first.event).to eq('create')
    end

    it 'creates an update version on role change' do
      expect {
        user.update!(role: :admin)
      }.to change { PaperTrail::Version.where(item_id: user.id, event: 'update').count }.by(1)
    end


    it 'does not create a version for untracked fields' do
      expect {
        user.update!(first_name: 'Changed')
      }.not_to change { PaperTrail::Version.where(item_id: user.id, event: 'update').count }
    end
  end
end
