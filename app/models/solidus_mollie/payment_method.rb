# frozen_string_literal: true

module SolidusMollie
  # A Solidus payment method backed by Mollie's hosted (redirect) checkout.
  #
  # Unlike credit-card gateways, Mollie does not authorise/capture
  # synchronously. The buyer is redirected to Mollie, and the *webhook* is the
  # source of truth for whether payment succeeded. See
  # SolidusMollie::CreateOrderPayment (redirect) and
  # SolidusMollie::ProcessWebhook (settlement).
  class PaymentMethod < ::Spree::PaymentMethod
    preference :api_key, :string
    # Optional. Force a single Mollie method (e.g. "ideal", "creditcard",
    # "bancontact"). Leave blank to let the buyer choose on Mollie's page.
    preference :mollie_method, :string

    def payment_source_class
      SolidusMollie::MollieSource
    end

    # Frontend/admin look for spree/checkout/payment/_mollie and friends.
    def partial_name
      'mollie'
    end

    def source_required?
      true
    end

    def payment_profiles_supported?
      false
    end

    # Money is moved on Mollie's side, so there is nothing to auto-capture here.
    def auto_capture?
      false
    end

    def test_mode?
      preferred_api_key.to_s.start_with?('test_')
    end

    def client
      SolidusMollie::Client.new(api_key: preferred_api_key)
    end

    # --- Solidus gateway interface ------------------------------------------
    # These are deliberately defensive. The normal checkout flow never calls
    # purchase/authorize/capture (we redirect instead), but implementing them
    # keeps Solidus happy if Order#process_payments! is ever invoked.

    def authorize(_amount, _source, _gateway_options = {})
      SolidusMollie::Response.pending('Awaiting Mollie redirect')
    end

    def purchase(_amount, _source, _gateway_options = {})
      SolidusMollie::Response.pending('Awaiting Mollie redirect')
    end

    def capture(_amount, _response_code, _gateway_options = {})
      SolidusMollie::Response.success('Captured by Mollie webhook')
    end

    # Refund. Solidus' Spree::Refund#perform! has varied across versions; accept
    # both (amount, response_code, options) and (amount, source, response_code,
    # options).
    def credit(amount_cents, *rest)
      options = rest.last.is_a?(Hash) ? rest.last : {}
      response_code = rest.reverse.find { |arg| arg.is_a?(String) } || options[:response_code]
      currency = refund_currency(options)

      client.create_refund(
        payment_id: response_code,
        amount: SolidusMollie::Client.cents_to_major(amount_cents, currency),
        currency: currency
      )
      SolidusMollie::Response.success('Mollie refund created', authorization: response_code)
    rescue StandardError => e
      Rails.logger.error("[solidus_mollie] refund failed: #{e.message}")
      SolidusMollie::Response.failure(e.message)
    end

    # Solidus calls try_void before issuing a refund. Cancel the Mollie payment
    # if it is still cancelable; otherwise return false so Solidus falls back to
    # a refund.
    def try_void(payment)
      remote = client.get_payment(payment.response_code)
      return false unless remote.respond_to?(:cancelable?) ? remote.cancelable? : remote.try(:cancelable)

      client.cancel_payment(payment.response_code)
      SolidusMollie::Response.success('Mollie payment canceled', authorization: payment.response_code)
    rescue StandardError => e
      Rails.logger.error("[solidus_mollie] void failed: #{e.message}")
      false
    end

    private

    def refund_currency(options)
      options[:currency] ||
        options[:originator]&.try(:payment)&.try(:currency) ||
        ::Spree::Config.try(:currency) ||
        'EUR'
    end
  end
end
