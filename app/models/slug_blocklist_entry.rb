# frozen_string_literal: true

class SlugBlocklistEntry < ApplicationRecord
  before_validation :normalize_term

  enum :match_type, {
    exact: 0,
    contains: 1
  }

  scope :enabled, -> { where(is_active: true) }

  validates :term,
            presence: true,
            length: { minimum: 2, maximum: 100 },
            uniqueness: { case_sensitive: false }
  validates :match_type, presence: true
  validates :is_active, inclusion: { in: [ true, false ] }
  validates :comment, length: { maximum: 2000 }, allow_blank: true

  # @param slug [String]
  # @return [ActiveRecord::Relation<SlugBlocklistEntry>]
  def self.matching(slug)
    normalized_slug = slug.to_s.strip.downcase
    enabled.select { |entry| entry.matches?(normalized_slug) }
  end

  # @param slug [String]
  # @return [Boolean]
  def matches?(slug)
    normalized_slug = slug.to_s.strip.downcase

    if exact?
      normalized_slug == term
    else
      normalized_slug.include?(term)
    end
  end

  # @return [String]
  def public_reason
    "Этот адрес магазина нельзя использовать. Выберите другой slug."
  end

  private

  def normalize_term
    self.term = term.to_s.strip.downcase if term.present?
  end
end
