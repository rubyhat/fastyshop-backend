class ShopCategory < ApplicationRecord
  validates :name,
            presence: true,
            length: { maximum: 100 },
            uniqueness: true,
            format: {
              with: /\A[a-z0-9\-]+\z/,
              message: "может содержать только латинские буквы, цифры и тире"
            }
  validates :title, presence: true, length: { maximum: 100 }
  validates :description, allow_blank: true, length: { maximum: 500 }
  validates :icon, allow_blank: true, length: { maximum: 255 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :is_active, inclusion: { in: [ true, false ] }
end
