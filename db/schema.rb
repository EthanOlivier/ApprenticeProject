# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_06_162257) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  create_table "leases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "storage_unit_id"
    t.decimal "cash_price", null: false
    t.daterange "occupancy_dates", null: false
    t.date "next_bill_date", null: false
    t.uuid "customer_id", null: false
    t.integer "company_id", null: false
    t.integer "billing_interval_id", null: false
    t.text "notes"
    t.integer "serial_num", null: false
    t.boolean "void", default: false, null: false
    t.text "z_gate_access_code"
    t.integer "bulk_storage_unit_id"
    t.integer "feet_leased"
    t.date "scheduled_move_out"
    t.boolean "tax_exempt", default: false, null: false
    t.date "auction_date"
  end
end
