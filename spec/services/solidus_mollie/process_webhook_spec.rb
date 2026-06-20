# frozen_string_literal: true

require 'spec_helper'

# This is the most important behaviour to cover: the webhook is what actually
# settles the order. These are starting points - expand with expired/failed
# transitions, double-delivery (idempotency), and amount-mismatch cases.
RSpec.describe SolidusMollie::ProcessWebhook do
  let(:payment_method) { create(:mollie_payment_method) }
  let(:source) { create(:mollie_source, payment_method: payment_method, mollie_payment_id: 'tr_abc') }

  # An order sitting at `confirm`, awaiting the Mollie result, with a pending
  # payment - the state CreateOrderPayment leaves things in.
  let(:order) do
    create(:order_with_line_items, state: 'confirm').tap do |o|
      o.payments.create!(
        amount: o.total,
        payment_method: payment_method,
        source: source,
        response_code: 'tr_abc',
        state: 'pending'
      )
    end
  end

  before { order } # build the graph

  context 'when Mollie reports the payment as paid' do
    before { stub_mollie_get(id: 'tr_abc', status: 'paid') }

    it 'completes the payment' do
      described_class.call(mollie_payment_id: 'tr_abc')
      expect(order.payments.reload.last).to be_completed
    end

    it 'completes the order' do
      described_class.call(mollie_payment_id: 'tr_abc')
      expect(order.reload).to be_complete
    end

    it 'is idempotent across repeated webhook deliveries' do
      2.times { described_class.call(mollie_payment_id: 'tr_abc') }
      expect(order.reload).to be_complete
      expect(order.payments.completed.count).to eq(1)
    end
  end

  context 'when Mollie reports the payment as failed' do
    before { stub_mollie_get(id: 'tr_abc', status: 'failed') }

    it 'fails the payment and leaves the order incomplete' do
      described_class.call(mollie_payment_id: 'tr_abc')
      expect(order.payments.reload.last).to be_failed
      expect(order.reload).not_to be_complete
    end
  end

  context 'when the Mollie id is unknown' do
    it 'raises PaymentNotFound (so the controller can ask Mollie to retry)' do
      expect do
        described_class.call(mollie_payment_id: 'tr_does_not_exist')
      end.to raise_error(SolidusMollie::ProcessWebhook::PaymentNotFound)
    end
  end
end
