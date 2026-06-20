# frozen_string_literal: true

module SolidusMollie
  # Creates a Mollie payment for an order and returns the hosted checkout URL the
  # buyer should be redirected to. The associated Spree::Payment is moved to
  # `pending` so Solidus knows it is awaiting an off-site result.
  class CreateOrderPayment
    Result = Struct.new(:checkout_url, :error, keyword_init: true) do
      def success?
        error.nil?
      end
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(order:, payment:, redirect_url:, webhook_url:)
      @order = order
      @payment = payment
      @redirect_url = redirect_url
      @webhook_url = webhook_url
    end

    def call
      payment_method = @payment.payment_method
      mollie = payment_method.client.create_payment(
        amount: @order.total,
        currency: @order.currency,
        description: description,
        redirect_url: @redirect_url,
        webhook_url: @webhook_url,
        method: payment_method.preferred_mollie_method,
        metadata: { order_number: @order.number, payment_number: @payment.number }
      )

      persist(mollie)
      Result.new(checkout_url: mollie.checkout_url)
    rescue StandardError => e
      Rails.logger.error("[solidus_mollie] failed to create payment for #{@order.number}: #{e.message}")
      Result.new(error: e.message)
    end

    private

    def persist(mollie)
      source = mollie_source
      source.update!(
        mollie_payment_id: mollie.id,
        mollie_method: mollie.try(:method),
        status: mollie.status
      )

      @payment.update!(response_code: mollie.id)
      @payment.pend! if @payment.checkout?
    end

    def mollie_source
      if @payment.source.is_a?(SolidusMollie::MollieSource)
        @payment.source
      else
        source = SolidusMollie::MollieSource.create!(
          payment_method: @payment.payment_method,
          user: @order.user
        )
        @payment.update!(source: source)
        source
      end
    end

    def description
      store_name = @order.try(:store)&.name || ::Spree::Store.try(:default)&.name || 'Order'
      "#{store_name} ##{@order.number}"
    end
  end
end
