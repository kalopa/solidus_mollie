# frozen_string_literal: true

require_relative 'lib/solidus_mollie/version'

Gem::Specification.new do |spec|
  spec.name        = 'solidus_mollie'
  spec.version     = SolidusMollie::VERSION
  spec.authors     = ['Kalopa Robotics']
  spec.email       = ['support@kalopa.com']
  spec.summary     = 'Mollie payments for Solidus'
  spec.description  = 'A Solidus extension that lets your store accept payments through ' \
                      'Mollie using their hosted (redirect) checkout and webhooks.'
  spec.homepage    = 'https://github.com/kalopa/solidus_mollie'
  spec.license     = 'BSD-2-Clause'

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.required_ruby_version = '>= 3.1'

  spec.files = Dir[
    'app/**/*',
    'config/**/*',
    'db/**/*',
    'lib/**/*',
    'README.md',
    'LICENSE'
  ]
  spec.require_paths = ['lib']

  spec.add_dependency 'mollie-api-ruby', '~> 4.0'
  spec.add_dependency 'solidus_core', ['>= 4.0', '< 5']
  spec.add_dependency 'solidus_support', '~> 0.8'

  spec.add_development_dependency 'solidus_dev_support', '~> 2.5'
end
