# frozen_string_literal: true

require 'bigdecimal'

module SolidusMollie
  # Thin wrapper around the mollie-api-ruby gem. Centralises API-key handling
  # and the (fiddly) amount formatting Mollie requires: a string value with
  # exactly the right number of decimals for the currency.
  class Client
    def initialize(api_key:)
      raise ArgumentError, 'Mollie API key is blank' if api_key.to_s.empty?

      @api_key = api_key
    end

    # amount: a BigDecimal/Numeric in MAJOR units (e.g. 10.00 for €10).
    def create_payment(amount:, currency:, description:, redirect_url:, webhook_url:,
                       method: nil, metadata: {})
      Mollie::Payment.create(
        amount: { value: self.class.format_amount(amount, currency), currency: currency },
        description: description,
        redirect_url: redirect_url,
        webhook_url: webhook_url,
        method: method.presence,
        metadata: metadata,
        api_key: @api_key
      )
    end

    def get_payment(payment_id)
      Mollie::Payment.get(payment_id, api_key: @api_key)
    end

    def cancel_payment(payment_id)
      Mollie::Payment.delete(payment_id, api_key: @api_key)
    end

    def create_refund(payment_id:, amount:, currency:)
      Mollie::Payment::Refund.create(
        payment_id: payment_id,
        amount: { value: self.class.format_amount(amount, currency), currency: currency },
        api_key: @api_key
      )
    end

    # --- formatting helpers --------------------------------------------------

    # Format a major-unit amount into the string Mollie expects, honouring the
    # currency's decimal places (EUR -> "10.00", JPY -> "10").
    def self.format_amount(amount, currency)
      format("%.#{currency_exponent(currency)}f", BigDecimal(amount.to_s))
    end

    # Convert a cents/minor-unit integer (as Solidus passes to #credit) into a
    # major-unit BigDecimal.
    def self.cents_to_major(cents, currency)
      BigDecimal(cents.to_s) / (10**currency_exponent(currency))
    end

    def self.currency_exponent(currency)
      ::Money::Currency.new(currency).exponent
    rescue StandardError
      2
    end
  end
end
