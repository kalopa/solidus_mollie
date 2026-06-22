# frozen_string_literal: true

module SolidusMollie
  class Engine < ::Rails::Engine
    include SolidusSupport::EngineExtensions if defined?(SolidusSupport::EngineExtensions)

    engine_name 'solidus_mollie'

    # NOT isolated: routes are drawn onto Spree's engine (see config/routes.rb)
    # so helpers resolve as spree.mollie_webhook_url / spree.mollie_return_url.

    # Register the payment method so it appears in the admin "New Payment Method"
    # provider dropdown. Runs right after core populates its defaults; the string
    # form avoids autoloading the model during boot and survives code reloads
    # (config.spree.payment_methods is a ClassConstantizer::Set that constantizes
    # on read and dedupes inserts).
    initializer 'solidus_mollie.register_payment_method', after: 'spree.register.payment_methods' do |app|
      app.config.spree.payment_methods << 'SolidusMollie::PaymentMethod'
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
