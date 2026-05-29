# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, first_name: 'Jane') }
  let(:mail) { described_class.welcome_email(user) }

  it 'renders subject' do
    expect(mail.subject).to eq('Welcome to the platform!')
  end

  it 'sends to user email' do
    expect(mail.to).to eq([user.email])
  end

  it 'includes first name in body' do
    expect(mail.body.encoded).to include('Jane')
  end
end
