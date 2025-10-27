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

ActiveRecord::Schema[8.0].define(version: 2025_10_06_211245) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "name", null: false
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "phone_number"
    t.integer "serial_num", null: false
    t.string "email"
    t.boolean "allow_upcoming_invoice_emails", default: true
    t.boolean "allow_past_due_invoice_emails", default: true
    t.boolean "allow_auto_pay_failure_emails", default: true
    t.boolean "allow_upcoming_card_expiration_emails", default: true
    t.text "alternate_contact_name"
    t.boolean "active_military", default: false, null: false
    t.text "address2"
    t.boolean "do_not_rent", default: false
    t.boolean "tax_exempt", default: false, null: false
    t.boolean "allow_payment_receipt_emails", default: true
    t.boolean "allow_upcoming_invoice_sms", default: true
    t.boolean "allow_past_due_invoice_sms", default: true
    t.boolean "allow_auto_pay_failure_sms", default: true
    t.boolean "allow_upcoming_card_expiration_sms", default: true
    t.boolean "allow_payment_receipt_sms", default: true
    t.boolean "lock_pricing_type", default: false, null: false
    t.boolean "ach_disabled", default: false, null: false
    t.text "alternate_contact_email"
    t.text "alternate_contact_phone"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
  end

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
    t.index ["company_id", "void"], name: "index_leases_on_company_id_and_void"
    t.index ["occupancy_dates"], name: "index_leases_on_occupancy_dates", using: :gist
    t.index ["storage_unit_id", "void"], name: "index_leases_on_storage_unit_id_and_void"
  end

  create_table "storage_units", force: :cascade do |t|
    t.integer "company_id", null: false
    t.boolean "disabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "disabled"], name: "index_storage_units_on_company_id_and_disabled"
  end
end
