# typed: strict
# frozen_string_literal: true

# @!attribute [rw] first_name
#   @return [String] имя пользователя (необязательное)
# @!attribute [rw] last_name
#   @return [String] фамилия пользователя (необязательное)
# @!attribute [rw] middle_name
#   @return [String, nil] отчество пользователя (необязательное)
# @!attribute [rw] phone
#   @return [String] номер телефона пользователя (уникальный)
# @!attribute [rw] email
#   @return [String] email пользователя (уникальный)
# @!attribute [rw] password
#   @return [String] виртуальное поле для валидации пароля
# @!attribute [rw] password_digest
#   @return [String] хэш пароля для авторизации
# @!attribute [rw] role
#   @return [Symbol] роль пользователя в системе (enum)
# @!attribute [rw] country_code
#   @return [String] код страны пользователя (например, "KZ")
# @!attribute [rw] account_status
#   @return [Symbol] статус жизненного цикла и ручной верификации аккаунта
#
# @!method seller_profile
#   @return [SellerProfile, nil]
#
# @!method build_seller_profile(attributes = {})
#   @param attributes [Hash]
#   @return [SellerProfile]

class User < ApplicationRecord
  ALLOWED_PASSWORD_CHARACTERS_PATTERN = /\A[A-Za-z0-9!*@#$%^&+=_-]+\z/

  has_secure_password
  has_one :seller_profile, dependent: :destroy
  has_many :product_properties, dependent: :destroy
  has_many :user_addresses, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :destroy

  before_validation :normalize_country_code
  before_validation :normalize_email
  before_validation :normalize_phone

  enum :role, {
    superadmin: 0,
    supermanager: 1,
    seller: 2,
    user: 3
  }, default: :user

  enum :account_status, {
    pending_review: 0,
    approved: 1,
    rejected: 2,
    blocked: 3,
    deactivated: 4
  }, default: :pending_review

  validates :phone, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country_code, presence: true
  validates :password_digest, presence: true
  validate :validate_password_complexity, if: -> { password.present? } # Валидация сложности пароля
  validate :validate_country_exists
  validate :validate_phone_format

  # @return [Boolean]
  def admin?
    superadmin? || supermanager?
  end

  # @return [String]
  def full_name
    [ first_name, last_name, middle_name ].compact_blank.join(" ").presence || phone_display || email
  end

  # @return [Boolean]
  def authenticatable?
    !blocked? && !deactivated?
  end

  # @return [String, nil]
  def phone_display
    phone.present? ? "+#{phone}" : nil
  end

  # @param value [String, nil]
  # @return [String, nil]
  def self.normalize_phone(value)
    value.to_s.gsub(/\D/, "").presence
  end

  def validate_password_complexity
    unless password.length >= 12
      errors.add(:password, "должен содержать минимум 12 символов")
    end

    unless password.match?(ALLOWED_PASSWORD_CHARACTERS_PATTERN)
      errors.add(:password, "может содержать только латинские буквы, цифры и разрешённые специальные символы")
    end

    unless password.match?(/[A-Z]/)
      errors.add(:password, "должен содержать хотя бы одну заглавную букву A-Z")
    end

    unless password.match?(/[a-z]/)
      errors.add(:password, "должен содержать хотя бы одну строчную букву a-z")
    end

    unless password.match?(/\d/)
      errors.add(:password, "должен содержать хотя бы одну цифру")
    end

    unless password.match?(/^.*(?=.*[!*@#$%^&+=_-]).*$/)
      errors.add(:password, "должен содержать хотя бы один специальный символ")
    end
  end

  private

  def normalize_country_code
    return if country_code.blank?

    self.country_code = country_code.to_s.strip.upcase
    @country_record = nil
  end

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end

  def normalize_phone
    return if phone.blank?

    raw_phone = phone.to_s.strip
    @phone_has_invalid_characters = raw_phone.match?(/[^\d\s+\-().]/)
    self.phone = self.class.normalize_phone(raw_phone)
  end

  def validate_country_exists
    return if country_code.blank?

    errors.add(:country_code, "должен соответствовать поддерживаемой стране") unless country_record
  end

  def validate_phone_format
    return if phone.blank?

    errors.add(:phone, "содержит недопустимые символы") if @phone_has_invalid_characters
    errors.add(:phone, "должен содержать только цифры после нормализации") unless phone.match?(/\A\d+\z/)

    prefix_digits = self.class.normalize_phone(country_record&.phone_prefix)
    return if prefix_digits.blank?

    unless phone.start_with?(prefix_digits)
      errors.add(:phone, "не соответствует телефонному коду выбранной страны")
    end
  end

  def country_record
    @country_record = Country.find_by(code: country_code)
  end
end
