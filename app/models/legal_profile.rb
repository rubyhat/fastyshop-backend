class LegalProfile < ApplicationRecord
  belongs_to :seller_profile

  validates :company_name, presence: true, length: { maximum: 255 }
  validates :tax_id, length: { maximum: 32 }
  validates :country_code, length: { is: 2 }
  validates :legal_form, presence: true, length: { maximum: 100 }
  validates :legal_address, length: { maximum: 500 }
end
