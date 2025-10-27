class AddIndexesForOccupancyQueries < ActiveRecord::Migration[8.0]
  def change
    add_index :leases, :occupancy_dates, using: :gist
    add_index :storage_units, [ :company_id, :disabled ]
    add_index :leases, [ :storage_unit_id, :void ]
    add_index :leases, [ :company_id, :void ]
  end
end
