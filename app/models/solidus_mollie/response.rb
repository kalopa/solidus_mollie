# frozen_string_literal: true

module SolidusMollie
  # Solidus serialises gateway responses into Spree::LogEntry as YAML and expects
  # an ActiveMerchant::Billing::Response-shaped object. We reuse that class
  # (active_merchant is a solidus_core dependency) so logging, #success? and
  # #authorization all behave as Solidus expects.
  module Response
    module_function

    def success(message, authorization: nil, params: {})
      build(true, message, params, authorization: authorization)
    end

    def failure(message, params: {})
      build(false, message, params)
    end

    def pending(message, params: {})
      build(true, message, params.merge('pending' => true))
    end

    def build(success, message, params, authorization: nil)
      ::ActiveMerchant::Billing::Response.new(
        success,
        message,
        params,
        authorization: authorization,
        test: false
      )
    end
  end
end
