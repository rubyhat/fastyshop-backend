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
    email: "superadmin@fastyshop.local",
    password: "UserPassword1@",
    role: :superadmin,
    account_status: :approved,
    country_code: "KZ"
  },
  {
    phone: "77000000002",
    email: "supermanager@fastyshop.local",
    password: "UserPassword1@",
    role: :supermanager,
    account_status: :approved,
    country_code: "KZ"
  },
  {
    phone: "77000000003",
    email: "seller@fastyshop.local",
    password: "UserPassword1@",
    role: :seller,
    account_status: :approved,
    country_code: "RU"
  },
  {
    phone: "77000000004",
    email: "user@fastyshop.local",
    password: "UserPassword1@",
    role: :user,
    account_status: :approved,
    country_code: "RU"
  }
]

users.each do |attrs|
  User.find_or_create_by!(phone: attrs[:phone]) do |user|
    user.email = attrs[:email]
    user.password = attrs[:password]
    user.password_confirmation = attrs[:password]
    user.role = attrs[:role]
    user.account_status = attrs[:account_status]
    user.country_code = attrs[:country_code]
  end
end

puts "🏬 Создаём категории магазинов..."
shop_categories = [
  {
    title: "Цветы",
    name: "flowers",
    description: "Свежие цветы",
    icon: "https://picsum.photos/id/106/64/64",
    position: 1,
    is_active: true
  },
  {
    title: "Электроника",
    name: "electronics",
    description: "Цифровая техника",
    icon: "https://picsum.photos/id/250/64/64",
    position: 2,
    is_active: true
  },
  {
    title: "Кофейня",
    name: "coffee-shop",
    description: "Свежий молотый кофе",
    icon: "https://picsum.photos/id/425/64/64",
    position: 3,
    is_active: true
  }
]

shop_categories.each do |attrs|
  ShopCategory.find_or_create_by!(name: attrs[:name]) do |category|
    category.title = attrs[:title]
    category.description = attrs[:description]
    category.icon = attrs[:icon]
    category.position = attrs[:position]
    category.is_active = attrs[:is_active]
  end
end

puts "✅ Все тестовые данные успешно посеяны!"
