# frozen_string_literal: true

# Mount onto Spree's engine so the helpers are available as
# spree.mollie_webhook_url / spree.mollie_return_url.
::Spree::Core::Engine.routes.draw do
  post '/mollie/webhook', to: 'solidus_mollie/callbacks#webhook', as: :mollie_webhook
  get  '/mollie/return',  to: 'solidus_mollie/callbacks#return',  as: :mollie_return
end
