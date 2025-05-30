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
# @!attribute [rw] is_active
#   @return [Boolean] флаг активности пользователя
#
# @!method seller_profile
#   @return [SellerProfile, nil]
#
# @!method build_seller_profile(attributes = {})
#   @param attributes [Hash]
#   @return [SellerProfile]

class User < ApplicationRecord
  has_secure_password
  has_one :seller_profile, dependent: :destroy
  has_many :product_properties, dependent: :destroy
  has_many :user_addresses, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :destroy

  enum :role, {
    superadmin: 0,
    supermanager: 1,
    seller: 2,
    user: 3
  }, default: :user

  validates :phone, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :country_code, presence: true
  validates :password_digest, presence: true
  validate :validate_password_complexity, if: -> { password.present? } # Валидация сложности пароля

  # @return [Boolean]
  def admin?
    superadmin? || supermanager?
  end

  def validate_password_complexity
    unless password.length >= 12
      errors.add(:password, "должен содержать минимум 12 символов")
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
end
