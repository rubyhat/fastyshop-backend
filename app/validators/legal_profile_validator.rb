# frozen_string_literal: true

class LegalProfileValidator < ActiveModel::Validator
  def validate(record)
    validate_country_rollout(record)
    validate_legal_form_supported(record)
    validate_registration_type(record)
    validate_registration_number_format(record)
  end

  private

  def validate_country_rollout(record)
    return if LegalProfile::ROLLED_OUT_COUNTRIES.include?(record.country_code)

    record.errors.add(:country_code, "страна временно не поддерживается для продавцов")
  end

  def validate_legal_form_supported(record)
    supported_forms = LegalProfile::LEGAL_FORMS_BY_COUNTRY.fetch(record.country_code, [])
    return if supported_forms.include?(record.legal_form_code)

    record.errors.add(:legal_form_code, "не поддерживается для выбранной страны")
  end

  def validate_registration_type(record)
    return if record.expected_registration_number_type.blank?
    return if record.expected_registration_number_type == record.registration_number_type

    record.errors.add(:registration_number_type, "не соответствует выбранной юридической форме")
  end

  def validate_registration_number_format(record)
    return unless record.country_code == "KZ"
    return if record.registration_number.blank?
    return if record.registration_number.match?(/\A\d{12}\z/)

    record.errors.add(:registration_number, "должен содержать 12 цифр для Казахстана")
  end
end
