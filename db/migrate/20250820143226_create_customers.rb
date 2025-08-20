class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers, id: :uuid do |t|
      t.integer :company_id,                            null: false
      t.string  :name,                                  null: false
      t.string  :address
      t.string  :city
      t.string  :state
      t.string  :postal_code
      t.string  :phone_number
      t.integer :serial_num,                            null: false
      t.string  :email
      t.boolean :allow_upcoming_invoice_emails,         default: true
      t.boolean :allow_past_due_invoice_emails,         default: true
      t.boolean :allow_auto_pay_failure_emails,         default: true
      t.boolean :allow_upcoming_card_expiration_emails, default: true
      t.text    :alternate_contact_name
      t.boolean :active_military,                       default: false, null: false
      t.text    :address2
      t.boolean :do_not_rent,                           default: false
      t.boolean :tax_exempt,                            default: false, null: false
      t.boolean :allow_payment_receipt_emails,          default: true
      t.boolean :allow_upcoming_invoice_sms,            default: true
      t.boolean :allow_past_due_invoice_sms,            default: true
      t.boolean :allow_auto_pay_failure_sms,            default: true
      t.boolean :allow_upcoming_card_expiration_sms,    default: true
      t.boolean :allow_payment_receipt_sms,             default: true
      t.boolean :lock_pricing_type,                     default: false, null: false
      t.boolean :ach_disabled,                          default: false, null: false
      t.text    :alternate_contact_email
      t.text    :alternate_contact_phone

      t.column :created_at, 'timestamp with time zone',
               default: -> { 'now()' }, null: false
      t.column :updated_at, 'timestamp with time zone',
               default: -> { 'now()' }, null: false
    end
  end
end
