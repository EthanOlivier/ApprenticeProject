class Company < ApplicationRecord
  validates_presence_of :name

  has_many :customers, inverse_of: :company
  has_many :storage_units, inverse_of: :company
  has_many :leases, inverse_of: :company
end
