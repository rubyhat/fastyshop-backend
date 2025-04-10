# frozen_string_literal: true

class LegalProfileValidator < ActiveModel::Validator
  SUPPORTED_COUNTRIES = %w[KZ RU].freeze # TODO: хардкод стран, нужно будет убрать
  MAX_PROFILES = 2 # TODO: заменить на значение из тарифа

  def validate(record)
    validate_legal_profile_limit(record)
    validate_country_supported(record)
  end

  private

  def validate_legal_profile_limit(record)
    if record.seller_profile&.legal_profiles&.count.to_i >= MAX_PROFILES
      record.errors.add(:base, "Достигнуто максимальное количество юридических профилей по Вашему тарифу")
    end
  end

  def validate_country_supported(record)
    unless SUPPORTED_COUNTRIES.include?(record.country_code)
      record.errors.add(:base, "Данная страна временно не поддерживается")
    end
  end
end
