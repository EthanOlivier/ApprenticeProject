require "csv"

class Customer < ApplicationRecord
  belongs_to :company, inverse_of: :customers

  has_many :notifications, inverse_of: :customer, dependent: :destroy
  has_one :sms_authorization, -> { active }, inverse_of: :customer
  has_many :sms_authorizations, inverse_of: :customer, dependent: :destroy

  has_many :invoices, inverse_of: :customer, dependent: :destroy
  has_many :past_due_invoices, -> { unpaid.past_due }, class_name: "Invoice", inverse_of: :customer, dependent: :destroy
  has_many :payments, inverse_of: :customer

  has_many :leases, dependent: :destroy
  has_many :active_leases, -> { merge(Lease.active) }, class_name: "Lease"
  has_many :active_storage_units, -> { merge(Lease.active) }, through: :leases, source: :storage_unit

  has_one :customer_balance, inverse_of: :customer
  has_one :auto_pay_agreement, -> { active }, inverse_of: :customer
  has_many :auto_pay_agreements, inverse_of: :customer, dependent: :destroy # exists for sake of deletions
  has_many :lease_agreements, through: :leases, dependent: :destroy
  has_many :customer_notes
  has_one :pinned_note, -> { pinned }, class_name: "CustomerNote"
  has_many :lease_agreement_requests, through: :leases, dependent: :destroy

  has_one :tokenized_payment_account, -> { active }, inverse_of: :customer
  has_many :tokenized_payment_accounts, inverse_of: :customer, dependent: :destroy # exists for sake of deletions

  has_many :in_progress_payment_account_creations, inverse_of: :customer, dependent: :destroy

  has_many :rental_requests, inverse_of: :customer, dependent: :destroy

  has_many :user_invitations, inverse_of: :customer, dependent: :destroy

  has_many :customers_customer_users, inverse_of: :customer, dependent: :destroy
  has_many :users, class_name: "CustomerUser", through: :customers_customer_users
  has_many :active_users, -> { active(true) }, class_name: "CustomerUser", through: :customers_customer_users, source: :user
  has_many :inactive_users, -> { active(false) }, class_name: "CustomerUser", through: :customers_customer_users, source: :user

  has_many :unpaid_invoices, -> { unpaid.past_due }, class_name: "Invoice", inverse_of: :customer, dependent: :destroy
  has_many :security_deposits, through: :leases

  has_many :drivers_licenses, inverse_of: :customer, dependent: :destroy # exists for sake of deletions
  has_many :customer_documents, inverse_of: :customer, dependent: :destroy # exists for sake of deletions

  has_one :billing_notice_user_invitation, inverse_of: :customer, dependent: :destroy

  validates_presence_of :name, :pricing_type_id
  validates_presence_of :email, message: "is required to send invitation email", on: :create, if: :send_invitation_email

  accepts_nested_attributes_for :pinned_note, allow_destroy: true

  after_create :invite_customer_user, if: :send_invitation_email
  after_create :create_billing_notice_user_invitation, unless: -> { send_invitation_email || users.present? }

  def balance
    customer_balance&.balance || 0
  end

  def notes
    pinned_note&.note
  end

  def past_due_amount
    unpaid_invoices.sum { _1.total_billed - _1.total_paid }
  end

  def auto_pay?
    !!auto_pay_agreement
  end

  attr_reader :send_invitation_email
  def send_invitation_email=(val)
    @send_invitation_email = CommandModel::Convert::Boolean.new.call val
  end

  def self.default_export_columns
    {
      "id" => "serial_num",
      "name" => "name",
      "address" => "address",
      "address2" => "address2",
      "city" => "city",
      "state" => "state",
      "postal_code" => "postal_code",
      "phone_number" => "phone_number",
      "email" => "email",
      "alternate_contact_name" => "alternate_contact_name",
      "alternate_contact_email" => "alternate_contact_email",
      "alternate_contact_phone" => "alternate_contact_phone",
      "notes" => "notes"
    }
  end

  def self.optional_export_columns
    {
      "balance" => "balance"
    }
  end

  def self.to_csv(customers, columns = default_export_columns.keys)
    c = columns.presence || default_export_columns.keys
    cols = default_export_columns.merge(optional_export_columns).filter { c.include?(_1) }
    CSV.from_enumerable(customers, cols)
  end

  def pending_lease_agreement_requests
    lease_agreement_requests.where(accepted_at: nil)
  end

  def change_pricing_type_id(pricing_type_id)
    return if lock_pricing_type?

    transaction do
      update_attribute!(:pricing_type_id, pricing_type_id)
      invoices.where("total_paid = 0 and not void").each do |invoice|
        ConvertInvoiceToPaymentType.execute(invoice:, pricing_type_id:)
      end
    end
  end

  def portal_access? = active_users.present?

  private

  def invite_customer_user
    # Purposely not checking for errors. If something goes wrong we don't want
    # to halt the creation of the user. (But for that matter, there is little
    # that can go wrong.)
    InviteCustomerUser.execute({ email: email, send_invitation: true }, customer: self)
  end
end
