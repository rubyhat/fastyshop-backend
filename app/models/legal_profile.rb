class LegalProfile < ApplicationRecord
  belongs_to :seller_profile
  has_many :shops, dependent: :restrict_with_error

  validates :company_name, presence: true, length: { maximum: 255 }
  validates :tax_id, length: { maximum: 32 }
  validates :country_code, length: { is: 2 }
  validates :legal_form, presence: true, length: { maximum: 100 }
  validates :legal_address, length: { maximum: 500 }

  validates_with LegalProfileValidator
end
