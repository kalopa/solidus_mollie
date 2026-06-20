# frozen_string_literal: true

source 'https://rubygems.org'

branch = ENV.fetch('SOLIDUS_BRANCH', 'main')
gem 'solidus', github: 'solidusio/solidus', branch: branch

# Needed for the checkout-redirect feature specs (provides Spree::CheckoutController).
gem 'solidus_starter_frontend'

# Provides ActiveSupport-flavoured DB adapters for the dummy app.
gem 'sqlite3'

group :test do
  gem 'rails-controller-testing'
end

# Pin Solidus for local development against the version this gem targets by
# exporting SOLIDUS_BRANCH=v4.6 (or set an explicit gem version here instead).

gemspec
