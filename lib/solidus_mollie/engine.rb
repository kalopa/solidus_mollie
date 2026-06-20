# frozen_string_literal: true

module SolidusMollie
  class Engine < ::Rails::Engine
    include SolidusSupport::EngineExtensions if defined?(SolidusSupport::EngineExtensions)

    engine_name 'solidus_mollie'

    # NOT isolated: routes are drawn onto Spree's engine (see config/routes.rb)
    # so helpers resolve as spree.mollie_webhook_url / spree.mollie_return_url.

    # Register the payment method so it appears in the admin "New Payment Method"
    # provider dropdown.
    initializer 'solidus_mollie.register_payment_method' do |app|
      app.reloader.to_prepare do
        methods = Rails.application.config.spree.payment_methods
        methods << SolidusMollie::PaymentMethod unless methods.include?(SolidusMollie::PaymentMethod)
      rescue StandardError => e
        Rails.logger.warn("[solidus_mollie] could not auto-register payment method: #{e.message}")
      end
    end

    # Prepend our checkout override so confirm-step orders paying with Mollie are
    # redirected to Mollie's hosted checkout instead of completing synchronously.
    config.to_prepare do
      SolidusMollie::Engine.prepare_decorators
    end

    def self.prepare_decorators
      Spree::CheckoutController.prepend(SolidusMollie::Spree::CheckoutControllerDecorator)
    rescue NameError
      Rails.logger.info(
        '[solidus_mollie] Spree::CheckoutController not found; skipping checkout override. ' \
        'For an API/headless frontend, call SolidusMollie::CreateOrderPayment yourself.'
      )
    end
  end
end
