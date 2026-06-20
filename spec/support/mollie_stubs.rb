# frozen_string_literal: true

# Helpers to fake the Mollie API so specs never hit the network.
#
# Usage:
#   include SolidusMollie::Specs::MollieStubs
#   stub_mollie_create(checkout_url: 'https://mollie.test/checkout/123', id: 'tr_abc')
#   stub_mollie_get('tr_abc', status: 'paid')
module SolidusMollie
  module Specs
    module MollieStubs
      # A minimal stand-in for a Mollie::Payment object.
      def fake_mollie_payment(id:, status: 'open', checkout_url: 'https://mollie.test/checkout/x',
                              method: 'ideal', cancelable: false)
        instance_double(
          'Mollie::Payment',
          id: id,
          status: status,
          method: method,
          checkout_url: checkout_url,
          cancelable?: cancelable,
          paid?: status == 'paid'
        )
      end

      # Stub the wrapper client so no real client is built from the API key.
      def stub_mollie_client(create: nil, get: nil)
        client = instance_double(SolidusMollie::Client)
        allow(client).to receive(:create_payment).and_return(create) if create
        allow(client).to receive(:get_payment).and_return(get) if get
        allow_any_instance_of(SolidusMollie::PaymentMethod).to receive(:client).and_return(client)
        client
      end

      def stub_mollie_create(id:, checkout_url:, status: 'open')
        payment = fake_mollie_payment(id: id, status: status, checkout_url: checkout_url)
        stub_mollie_client(create: payment)
        payment
      end

      def stub_mollie_get(id:, status:)
        payment = fake_mollie_payment(id: id, status: status)
        stub_mollie_client(get: payment)
        payment
      end
    end
  end
end

RSpec.configure do |config|
  config.include SolidusMollie::Specs::MollieStubs
end
