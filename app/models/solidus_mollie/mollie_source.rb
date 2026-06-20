# frozen_string_literal: true

module SolidusMollie
  # Persists the Mollie payment id and last-known status alongside a
  # Spree::Payment. The buyer enters no card data here (that happens on Mollie's
  # hosted page), so this source has no validated fields.
  class MollieSource < ::Spree::PaymentSource
    self.table_name = 'solidus_mollie_sources'

    # Off-site payments are not reusable for one-click in this version.
    def reusable?
      false
    end

    def actions
      %w[void credit]
    end

    def can_void?(payment)
      payment.pending? || payment.checkout?
    end

    def can_credit?(payment)
      payment.completed? && payment.credit_allowed.positive?
    end

    def paid?
      SolidusMollie::PAID_STATUSES.include?(status)
    end
  end
end
