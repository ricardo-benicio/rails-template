# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WelcomeEmailJob, type: :job do
  let(:user) { create(:user) }

  it 'delivers welcome email' do
    expect { described_class.perform_now(user.id) }
      .to change { ActionMailer::Base.deliveries.count }.by(1)
  end

  it 'sends to correct recipient' do
    described_class.perform_now(user.id)
    expect(ActionMailer::Base.deliveries.last.to).to include(user.email)
  end

  it 'does nothing when user not found' do
    expect { described_class.perform_now('nonexistent-id') }
      .not_to change { ActionMailer::Base.deliveries.count }
  end
end
