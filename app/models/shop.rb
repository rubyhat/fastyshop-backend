class Shop < ApplicationRecord
  belongs_to :seller_profile
  belongs_to :legal_profile
  belongs_to :shop_category
  has_many :product_categories, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :destroy

  enum :shop_type, {
    online: 1,
    offline: 2,
    hybrid: 3
  }

  before_validation :generate_slug, on: :create

  validates :title, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, length: { maximum: 100 }
  validates :contact_phone, presence: true, length: { maximum: 32 }
  validates :contact_email, allow_blank: true, length: { maximum: 100 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :physical_address, allow_blank: true, length: { maximum: 255 }
  validates :is_active, inclusion: { in: [ true, false ] }
  validates :shop_type, presence: true

  validates_with ShopCreateValidator, on: :create

  private

  def generate_slug
    return if slug.present? && slug_changed?
    return errors.add(:base, "Не задано название магазина") unless title

    base_slug = title.to_s.parameterize[0..99]
    candidate = base_slug
    counter = 1

    while self.class.where.not(id: self.id).exists?(slug: candidate)
      counter += 1
      candidate = "#{base_slug}-#{counter}"
    end

    if candidate
      self.slug = candidate
    else
      errors.add(:base, "Slug не был сгенерирован")
    end
  end
end
