# solidus_mollie

Accept [Mollie](https://www.mollie.com) payments in your [Solidus](https://solidus.io)
store using Mollie's **hosted checkout** (the buyer is redirected to Mollie to pay)
and **webhooks** for settlement.

Tested against the stack it was written for: **Solidus 4.6 / Rails 7.1 / Ruby 3.2**,
with `mollie-api-ruby ~> 4`.

## How it works (read this first)

Mollie is **not** a synchronous credit-card gateway, so this is not a normal
ActiveMerchant-style `authorize`/`capture` extension. The flow is:

1. Buyer selects Mollie at the checkout **payment** step. A `Spree::Payment` is
   created with a `SolidusMollie::MollieSource` (no card data is collected).
2. At the **confirm** step, instead of completing the order synchronously, the
   buyer is redirected to Mollie's hosted page. The payment is moved to
   `pending`. (See `SolidusMollie::CreateOrderPayment` and the
   `Spree::CheckoutController` override.)
3. The buyer pays on Mollie and is sent back to `/mollie/return`, which forwards
   them to their order page.
4. Mollie also POSTs to `/mollie/webhook` — **this is the source of truth.**
   `SolidusMollie::ProcessWebhook` re-fetches the authoritative status, marks the
   `Spree::Payment` complete/failed, and completes the order. It is idempotent
   because Mollie may call the webhook more than once.

> Because the webhook is what completes the order, **Mollie must be able to reach
> your app over a public HTTPS URL**, including in development. Use a tunnel such
> as `ngrok` or `cloudflared` locally — Mollie will not call `localhost`.

## Installation

Add to your store's `Gemfile`:

```ruby
gem 'solidus_mollie'
```

Then:

```bash
bundle install
bin/rails generate solidus_mollie:install
bin/rails db:migrate
```

## Configuration

1. In the admin, go to **Configuration → Payment Methods → New Payment Method**.
2. Choose **`SolidusMollie::PaymentMethod`** as the provider.
3. Paste your Mollie **API key** (`test_…` for testing, `live_…` for production).
4. Optionally set **Mollie method** to force a single method (e.g. `ideal`,
   `creditcard`, `bancontact`). Leave blank to let the buyer choose on Mollie's page.

The key prefix (`test_`/`live_`) determines test vs live mode automatically.

## Frontend

The gem ships a `spree/checkout/payment/_mollie` partial (an informational note)
and prepends a `Spree::CheckoutController#update` override that performs the
redirect. This works with `solidus_starter_frontend` out of the box.

If you run a **headless / API frontend**, the controller override is skipped.
Trigger the redirect yourself after confirm:

```ruby
result = SolidusMollie::CreateOrderPayment.call(
  order: order,
  payment: order.payments.detect { |p| p.checkout? && p.payment_method.is_a?(SolidusMollie::PaymentMethod) },
  redirect_url: mollie_return_url(order_number: order.number, token: order.token),
  webhook_url: mollie_webhook_url
)
# => redirect the buyer to result.checkout_url
```

## Refunds & cancellation

Refunds from the Solidus admin call `PaymentMethod#credit`, which creates a Mollie
refund. Cancelling a still-cancelable Mollie payment is attempted via `try_void`;
otherwise Solidus falls back to a refund.

## Development & tests

The extension is scaffolded with `solidus_dev_support`, which generates a dummy
Solidus app under `spec/dummy` to test against.

```bash
bin/setup                      # bundle + generate the dummy app
bin/rake                       # run the full spec suite (extension:specs)
bundle exec rspec spec/services/solidus_mollie/process_webhook_spec.rb  # one file
SOLIDUS_BRANCH=v4.6 bin/setup  # pin a specific Solidus version
bin/sandbox                    # build a runnable sandbox store under ./sandbox
```

Bundled specs to build on:

- `spec/services/solidus_mollie/process_webhook_spec.rb` — settlement (paid /
  failed / idempotent / unknown-id). This is the behaviour most worth covering.
- `spec/requests/solidus_mollie/callbacks_spec.rb` — webhook + return endpoints.
- `spec/models/solidus_mollie/payment_method_spec.rb` — test-mode detection, refunds.
- `spec/support/mollie_stubs.rb` — helpers to fake the Mollie API so specs never
  hit the network (`stub_mollie_get`, `stub_mollie_create`).

### Testing against Mollie for real

Mollie has no separate sandbox URL — use a **test API key** (`test_…`) on the
payment method. Test payments are fully isolated from live data, and Mollie's
hosted page is replaced by a screen where you choose the resulting status
(Paid / Failed / Expired / Cancelled). Because settlement is webhook-driven,
Mollie must reach `/mollie/webhook` over a public HTTPS URL even in test mode —
run a tunnel (`ngrok http 3000`) and use the public host.

## Known limitations / TODO

- No one-click / reusable mandates (sources are non-reusable in this version).
- No partial-payment handling beyond a single payment per order.
- A buyer can technically re-enter checkout while an order sits in `confirm`
  awaiting a Mollie result; revisit if this matters for your flow.

## License

BSD-2-Clause.
