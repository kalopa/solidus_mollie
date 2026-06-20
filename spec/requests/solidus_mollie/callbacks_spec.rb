# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Mollie callbacks', type: :request do
  describe 'POST /mollie/webhook' do
    it 'hands the id to ProcessWebhook and returns 200 on success' do
      expect(SolidusMollie::ProcessWebhook).to receive(:call).with(mollie_payment_id: 'tr_abc')

      post '/mollie/webhook', params: { id: 'tr_abc' }
      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 for an unknown payment so Mollie retries' do
      allow(SolidusMollie::ProcessWebhook).to receive(:call)
        .and_raise(SolidusMollie::ProcessWebhook::PaymentNotFound)

      post '/mollie/webhook', params: { id: 'tr_missing' }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /mollie/return' do
    let(:order) { create(:completed_order_with_totals) }

    it 'redirects the buyer to their order page' do
      get '/mollie/return', params: { order_number: order.number, token: order.token }
      expect(response).to redirect_to(spree.order_url(order, token: order.token))
    end

    it 'rejects a mismatched token' do
      get '/mollie/return', params: { order_number: order.number, token: 'wrong' }
      expect(response).to redirect_to(spree.root_path)
    end
  end
end
