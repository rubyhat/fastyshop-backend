# frozen_string_literal: true

# Адрес доставки пользователя
#
# @!attribute user_id
#   @return [UUID] Владелец адреса
# @!attribute label
#   @return [String] Название (Дом, Офис...)
# @!attribute is_default
#   @return [Boolean] Признак адреса по умолчанию
#
class UserAddress < ApplicationRecord
  belongs_to :user

  validates :label, :country_code, :city, :street, :house, :contact_name, :contact_phone, presence: true
  validates :is_default, inclusion: { in: [ true, false ] }

  validate :max_10_addresses_per_user
  validate :only_one_default_address

  private

  def max_10_addresses_per_user
    return errors.add(:base, "Пользователь не определен") unless user

    if user.user_addresses.count > 10 && new_record?
      errors.add(:base, "Можно сохранить не более 10 адресов")
    end
  end

  def only_one_default_address
    return unless is_default?
    return errors.add(:base, "Пользователь не определен") unless user

    if user.user_addresses.where(is_default: true).where.not(id: id).exists?
      errors.add(:base, "По-умолчанию может быть только один адрес")
    end
  end
end
