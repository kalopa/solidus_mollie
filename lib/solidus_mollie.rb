# frozen_string_literal: true

require 'mollie-api-ruby'
require 'solidus_core'
require 'solidus_mollie/version'
require 'solidus_mollie/engine'

module SolidusMollie
  # Mollie payment statuses that mean "money has been received".
  PAID_STATUSES = %w[paid].freeze
  # Statuses that mean the payment will never succeed and should be failed.
  FAILED_STATUSES = %w[failed expired canceled].freeze
end
