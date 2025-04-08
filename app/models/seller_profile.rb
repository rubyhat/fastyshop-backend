# frozen_string_literal: true

# todo: реализовать методы защиты от парсинга данных компаний

class SellerProfile < ApplicationRecord
  belongs_to :user

  before_validation :generate_slug, on: :create

  validates :slug, presence: true, uniqueness: true

  private

  def generate_slug
    return if slug.present? && slug_changed? # не перезаписывать вручную заданный

    base_slug = display_name.to_s.parameterize
    candidate = base_slug
    counter = 1

    while SellerProfile.exists?(slug: candidate)
      counter += 1
      candidate = "#{base_slug}-#{counter}"
    end

    self.slug = candidate
  end
end
