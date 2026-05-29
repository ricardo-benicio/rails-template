# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Accounts', type: :request do
  let(:owner) { create(:user) }
  let(:other)  { create(:user) }
  let!(:account) do
    acc = create(:account, owner: owner)
    create(:account_membership, account: acc, user: owner, role: :owner)
    acc
  end

  describe 'GET /api/v1/accounts' do
    it 'returns accounts for current user' do
      get '/api/v1/accounts', headers: authenticated_headers(owner)
      expect(response).to have_http_status(:ok)
      expect(json_response[:accounts].length).to eq(1)
    end

    it 'does not return accounts user is not member of' do
      get '/api/v1/accounts', headers: authenticated_headers(other)
      expect(response).to have_http_status(:ok)
      expect(json_response[:accounts]).to be_empty
    end
  end

  describe 'POST /api/v1/accounts' do
    it 'creates an account and owner membership' do
      expect {
        post '/api/v1/accounts',
             params: { account: { name: 'Acme Corp' } }.to_json,
             headers: authenticated_headers(owner)
      }.to change(Account, :count).by(1)
         .and change(AccountMembership, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response[:account][:name]).to eq('Acme Corp')
    end
  end

  describe 'GET /api/v1/accounts/:id' do
    it 'returns account for member' do
      get "/api/v1/accounts/#{account.id}", headers: authenticated_headers(owner)
      expect(response).to have_http_status(:ok)
      expect(json_response[:account][:slug]).to eq(account.slug)
    end

    it 'returns 404 for non-member' do
      get "/api/v1/accounts/#{account.id}", headers: authenticated_headers(other)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/accounts/:id' do
    it 'updates account as owner' do
      patch "/api/v1/accounts/#{account.id}",
            params: { account: { name: 'New Name' } }.to_json,
            headers: authenticated_headers(owner)
      expect(response).to have_http_status(:ok)
    end

    it 'returns 403 for non-owner member' do
      member = create(:user)
      create(:account_membership, account: account, user: member, role: :member)
      patch "/api/v1/accounts/#{account.id}",
            params: { account: { name: 'Hack' } }.to_json,
            headers: authenticated_headers(member)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
