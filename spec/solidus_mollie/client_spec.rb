# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusMollie::Client do
  describe '.format_amount' do
    it 'formats EUR with two decimals' do
      expect(described_class.format_amount(BigDecimal('10'), 'EUR')).to eq('10.00')
    end

    it 'formats JPY with no decimals' do
      expect(described_class.format_amount(BigDecimal('1000'), 'JPY')).to eq('1000')
    end
  end

  describe '.cents_to_major' do
    it 'converts EUR cents to a major amount' do
      expect(described_class.cents_to_major(1099, 'EUR')).to eq(BigDecimal('10.99'))
    end
  end

  describe '#initialize' do
    it 'rejects a blank api key' do
      expect { described_class.new(api_key: '') }.to raise_error(ArgumentError)
    end
  end
end
