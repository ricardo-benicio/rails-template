# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WelcomeNotification, type: :model do
  let(:user) { create(:user) }

  it 'creates a database notification record' do
    expect {
      described_class.with(user: user).deliver(user)
    }.to change { Noticed::Notification.count }.by(1)
  end

  it 'enqueues a Noticed delivery job' do
    expect {
      described_class.with(user: user).deliver(user)
    }.to have_enqueued_job(Noticed::DeliveryMethods::Email)
      .or have_enqueued_job(Noticed::EventJob)
  end
end
