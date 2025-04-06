# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


puts "🌍 Добавляем страны..."
Country.find_or_create_by!(code: "KZ") do |country|
  country.name = "Казахстан"
  country.phone_prefix = "+7"
end

puts "👑 Создаём супер-админа..."
User.find_or_create_by!(phone: "+77001112233") do |user|
  user.email = "admin@kagi.local"
  user.password = "supersecure"
  user.password_confirmation = "supersecure"
  user.role = :superadmin
  user.country_code = "KZ"
  user.is_active = true
end

puts "✅ Все тестовые данные успешно посеяны!"
