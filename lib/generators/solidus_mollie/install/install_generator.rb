# frozen_string_literal: true

require 'rails/generators'

module SolidusMollie
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      class_option :auto_run_migrations, type: :boolean, default: false

      def copy_initializer
        template 'initializer.rb', 'config/initializers/solidus_mollie.rb'
      end

      def copy_migrations
        rake 'railties:install:migrations FROM=solidus_mollie'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] ||
                         ['', 'y', 'Y'].include?(ask('Run migrations now? [Yn]'))
        if run_migrations
          rake 'db:migrate'
        else
          say_status :skip, 'migrations (run `rails db:migrate` later)', :yellow
        end
      end

      def show_readme
        say <<~MSG, :green

          solidus_mollie installed.

          Next steps:
            1. Add a payment method in the admin (Configuration -> Payment Methods -> New),
               choosing "SolidusMollie::PaymentMethod" as the provider, and paste your
               Mollie API key (test_... or live_...).
            2. Make sure your store is reachable over HTTPS at a public URL so Mollie can
               reach the webhook at /mollie/webhook (use a tunnel like ngrok in dev).
        MSG
      end
    end
  end
end
