# typed: strict
# frozen_string_literal: true

# @!attribute [rw] code
#   @return [String] буквенный код страны (например, "KZ")
# @!attribute [rw] name
#   @return [String] полное название страны
# @!attribute [rw] phone_prefix
#   @return [String] телефонный префикс страны (например, "+7")

class Country < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :phone_prefix, presence: true
end
