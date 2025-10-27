class CreateStorageUnits < ActiveRecord::Migration[8.0]
  def change
    create_table :storage_units do |t|
      t.integer :company_id, null: false
      t.boolean :disabled, null: false, default: false

      t.timestamps
    end
  end
end
