# frozen_string_literal: true

class ShopSlugHistory < ApplicationRecord
  belongs_to :shop

  before_validation :normalize_slug

  validates :slug,
            presence: true,
            length: { minimum: 3, maximum: 50 },
            format: {
              with: Shop::SLUG_FORMAT,
              message: "может содержать только латинские строчные буквы, цифры и дефис без двойных или крайних дефисов"
            },
            uniqueness: { case_sensitive: false }

  private

  def normalize_slug
    self.slug = slug.to_s.strip.downcase if slug.present?
  end
end
