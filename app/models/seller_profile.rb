# frozen_string_literal: true

# todo: реализовать методы защиты от парсинга данных компаний

class SellerProfile < ApplicationRecord
  belongs_to :user
  has_many :legal_profiles, dependent: :destroy

  before_validation :generate_slug, on: :create

  validates :display_name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :logo_url, length: { maximum: 255 }, allow_blank: true

  validate :legal_profile_limit, on: :create

  # todo: хардкод лимита, изменить когда будут тарифы
  def max_legal_profiles_reached?
    legal_profiles.count >= 2
  end

  private

  def legal_profile_limit
    if seller_profile&.max_legal_profiles_reached?
      errors.add(:base, "Достигнуто максимальное количество юридических профилей")
    end
  end

  def generate_slug
    return if slug.present? && slug_changed? # не перезаписывать вручную заданный

    base_slug = display_name.to_s.parameterize[0..99]
    candidate = base_slug
    counter = 1

    while SellerProfile.exists?(slug: candidate)
      counter += 1
      candidate = "#{base_slug}-#{counter}"
    end

    self.slug = candidate
  end
end
