# frozen_string_literal: true

module SolidusMollie
  # Settlement logic, driven by Mollie's webhook (the source of truth). Looks up
  # the local payment from the Mollie id, re-fetches the authoritative status
  # from Mollie, then advances the Spree::Payment and order. Designed to be
  # idempotent: Mollie may call the webhook several times.
  class ProcessWebhook
    class PaymentNotFound < StandardError; end

    def self.call(mollie_payment_id:)
      new(mollie_payment_id: mollie_payment_id).call
    end

    def initialize(mollie_payment_id:)
      @mollie_payment_id = mollie_payment_id
    end

    def call
      raise PaymentNotFound, 'missing id' if @mollie_payment_id.to_s.empty?

      source = SolidusMollie::MollieSource.find_by(mollie_payment_id: @mollie_payment_id)
      raise PaymentNotFound, @mollie_payment_id unless source

      payment = ::Spree::Payment.find_by(source: source)
      raise PaymentNotFound, "no payment for #{@mollie_payment_id}" unless payment

      remote = payment.payment_method.client.get_payment(@mollie_payment_id)
      source.update!(status: remote.status)

      settle(payment, remote.status)
      payment
    end

    private

    def settle(payment, status)
      ::ActiveRecord::Base.transaction do
        if SolidusMollie::PAID_STATUSES.include?(status)
          mark_paid(payment)
        elsif SolidusMollie::FAILED_STATUSES.include?(status)
          mark_failed(payment)
        end
        # open / pending / authorized: leave as-is and wait for the next webhook.
      end
    end

    def mark_paid(payment)
      return if payment.completed?

      payment.started_processing! if payment.checkout?
      payment.complete! unless payment.completed?
      complete_order(payment.order)
    end

    def mark_failed(payment)
      return if payment.failed? || payment.void?

      payment.failure! if payment.pending? || payment.processing? || payment.checkout?
    end

    def complete_order(order)
      return unless order.confirm?

      order.complete!
    end
  end
end
