# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusMollie::PaymentMethod do
  subject(:payment_method) { build(:mollie_payment_method) }

  it 'uses the Mollie source' do
    expect(payment_method.payment_source_class).to eq(SolidusMollie::MollieSource)
  end

  it 'does not auto-capture (money moves on Mollie)' do
    expect(payment_method.auto_capture?).to be(false)
  end

  describe '#test_mode?' do
    it 'is true for test_ keys' do
      payment_method.preferred_api_key = 'test_abc'
      expect(payment_method.test_mode?).to be(true)
    end

    it 'is false for live_ keys' do
      payment_method.preferred_api_key = 'live_abc'
      expect(payment_method.test_mode?).to be(false)
    end
  end

  describe '#credit' do
    it 'creates a Mollie refund and returns a successful response' do
      client = instance_double(SolidusMollie::Client)
      allow(payment_method).to receive(:client).and_return(client)
      expect(client).to receive(:create_refund).with(
        payment_id: 'tr_abc', amount: BigDecimal('5.00'), currency: 'EUR'
      )

      response = payment_method.credit(500, 'tr_abc', currency: 'EUR')
      expect(response.success?).to be(true)
    end
  end
end
