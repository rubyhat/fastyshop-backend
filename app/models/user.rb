# typed: strict
# frozen_string_literal: true

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

class User < ApplicationRecord
  has_secure_password

  enum :role, {
    superadmin: 0,
    supermanager: 1,
    seller: 2,
    user: 3
  }, default: :user

  validates :phone, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :password_digest, presence: true
  validates :country_code, presence: true

  # @return [Boolean]
  def admin?
    superadmin? || supermanager?
  end
end
