class StorageUnit < ApplicationRecord
  belongs_to :company, inverse_of: :storage_units

  has_many :leases, inverse_of: :storage_unit, dependent: :destroy
end
