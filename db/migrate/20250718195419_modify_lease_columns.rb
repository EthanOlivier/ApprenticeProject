class ModifyLeaseColumns < ActiveRecord::Migration[8.0]
  def change
    change_column :leases, :cash_price, :numeric, precision: 8, scale: 2, null: false
    change_column :leases, :occupancy_dates, :daterange, null: false
    change_column :leases, :next_bill_date, :date, null: false
    change_column :leases, :customer_id, :uuid, null: false
    change_column :leases, :company_id, :integer, null: false
    change_column :leases, :billing_interval_id, :integer, null: false
    change_column :leases, :serial_num, :integer, null: false
    change_column :leases, :void, :boolean, null: false, default: false
    change_column :leases, :tax_exempt, :boolean, null: false, default: false
    remove_column :leases, :created_at, :datetime
    remove_column :leases, :updated_at, :datetime
  end
end
