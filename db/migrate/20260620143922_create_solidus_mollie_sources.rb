# frozen_string_literal: true

class CreateSolidusMollieSources < ActiveRecord::Migration[7.1]
  def change
    create_table :solidus_mollie_sources do |t|
      t.string :mollie_payment_id
      t.string :mollie_method
      t.string :status
      t.references :payment_method
      t.references :user

      t.timestamps
    end

    add_index :solidus_mollie_sources, :mollie_payment_id, unique: true
  end
end
