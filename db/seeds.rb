# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# frozen_string_literal: true

puts "🌍 Добавляем страны..."

[
  { code: "KZ", name: "Казахстан", phone_prefix: "+7" },
  { code: "RU", name: "Россия", phone_prefix: "+7" }
].each do |country_attrs|
  Country.find_or_create_by!(code: country_attrs[:code]) do |country|
    country.name = country_attrs[:name]
    country.phone_prefix = country_attrs[:phone_prefix]
  end
end

puts "👑 Создаём пользователей по ролям..."

users = [
  {
    phone: "77000000001",
    email: "superadmin@kagi.local",
    password: "Superadmin1@",
    role: :superadmin,
    country_code: "KZ"
  },
  {
    phone: "77000000002",
    email: "supermanager@kagi.local",
    password: "Supermanager1@",
    role: :supermanager,
    country_code: "KZ"
  },
  {
    phone: "77000000003",
    email: "seller@kagi.local",
    password: "Selleruser1@",
    role: :seller,
    country_code: "RU"
  },
  {
    phone: "77000000004",
    email: "user@kagi.local",
    password: "Regularuser1@",
    role: :user,
    country_code: "RU"
  }
]

users.each do |attrs|
  User.find_or_create_by!(phone: attrs[:phone]) do |user|
    user.email = attrs[:email]
    user.password = attrs[:password]
    user.password_confirmation = attrs[:password]
    user.role = attrs[:role]
    user.country_code = attrs[:country_code]
    user.is_active = true
  end
end

puts "✅ Все тестовые данные успешно посеяны!"
