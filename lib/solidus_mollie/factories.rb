# frozen_string_literal: true

FactoryBot.define do
  factory :mollie_payment_method, class: 'SolidusMollie::PaymentMethod' do
    name { 'Mollie' }
    available_to_admin { true }
    available_to_users { true }
    preferences { { api_key: 'test_fakekey', mollie_method: '' } }
  end

  factory :mollie_source, class: 'SolidusMollie::MollieSource' do
    association :payment_method, factory: :mollie_payment_method
    mollie_payment_id { "tr_#{SecureRandom.alphanumeric(10)}" }
    status { 'open' }
  end
end
