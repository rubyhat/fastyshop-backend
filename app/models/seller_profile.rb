# frozen_string_literal: true

# todo: реализовать методы защиты от парсинга данных компаний

class SellerProfile < ApplicationRecord
  belongs_to :user
  has_many :legal_profiles, dependent: :destroy
  has_many :shops, dependent: :restrict_with_error

  before_validation :generate_slug, on: :create

  validates :display_name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :logo_url, length: { maximum: 255 }, allow_blank: true

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
