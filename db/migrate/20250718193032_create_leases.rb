class CreateLeases < ActiveRecord::Migration[8.0]
  def change
    create_table :leases, id: false do |t|
      t.uuid :id, primary_key: true
      t.integer :storage_unit_id
      t.decimal :cash_price
      t.daterange :occupancy_dates
      t.date :next_bill_date
      t.uuid :customer_id
      t.integer :company_id
      t.integer :billing_interval_id
      t.text :notes
      t.integer :serial_num
      t.boolean :void
      t.text :z_gate_access_code
      t.integer :bulk_storage_unit_id
      t.integer :feet_leased
      t.date :scheduled_move_out
      t.boolean :tax_exempt
      t.date :auction_date

      t.timestamps
    end
  end
end
