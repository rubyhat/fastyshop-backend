require 'rails_helper'

RSpec.describe User, type: :model do
  before do
    Country.find_or_create_by!(code: "KZ") do |country|
      country.name = "Казахстан"
      country.phone_prefix = "+7"
    end
  end

  describe "defaults" do
    it "по умолчанию создаёт пользователя с ролью user и статусом pending_review" do
      user = described_class.new(
        phone: "+77001234567",
        email: "user@example.com",
        password: "Password123!",
        password_confirmation: "Password123!",
        country_code: "KZ"
      )

      expect(user.role).to eq("user")
      expect(user.account_status).to eq("pending_review")
    end
  end

  describe "нормализация" do
    it "нормализует телефон в строку цифр без форматирования" do
      user = build(:user, phone: "+7 (700) 123-45-67")

      expect(user).to be_valid
      expect(user.phone).to eq("77001234567")
      expect(user.phone_display).to eq("+77001234567")
    end

    it "нормализует email" do
      user = build(:user, email: "  USER@Example.COM  ")

      expect(user).to be_valid
      expect(user.email).to eq("user@example.com")
    end

    it "нормализует country_code" do
      user = build(:user, country_code: " kz ")

      expect(user).to be_valid
      expect(user.country_code).to eq("KZ")
    end
  end

  describe "валидация телефона" do
    it "запрещает буквы в телефоне" do
      user = build(:user, phone: "+7ABC7001234567")

      expect(user).not_to be_valid
      expect(user.errors[:phone]).to include("содержит недопустимые символы")
    end

    it "проверяет телефонный код страны" do
      Country.find_or_create_by!(code: "US") do |country|
        country.name = "США"
        country.phone_prefix = "+1"
      end

      user = build(:user, phone: "+77001234567", country_code: "US")

      expect(user).not_to be_valid
      expect(user.errors[:phone]).to include("не соответствует телефонному коду выбранной страны")
    end

    it "требует существующую страну" do
      user = build(:user, country_code: "ZZ")

      expect(user).not_to be_valid
      expect(user.errors[:country_code]).to include("должен соответствовать поддерживаемой стране")
    end
  end

  describe "валидация email" do
    it "проверяет case-insensitive uniqueness" do
      create(:user, email: "user@example.com")
      duplicate = build(:user, email: "USER@example.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it "проверяет формат email" do
      user = build(:user, email: "invalid-email")

      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end
  end

  describe "валидация пароля" do
    it "запрещает пароль короче 12 символов" do
      user = build(:user, password: "Pass1!", password_confirmation: "Pass1!")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("должен содержать минимум 12 символов")
    end

    it "запрещает пароль без заглавной латинской буквы" do
      user = build(:user, password: "password123!", password_confirmation: "password123!")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("должен содержать хотя бы одну заглавную букву A-Z")
    end

    it "запрещает пароль без строчной латинской буквы" do
      user = build(:user, password: "PASSWORD123!", password_confirmation: "PASSWORD123!")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("должен содержать хотя бы одну строчную букву a-z")
    end

    it "запрещает пароль без цифры" do
      user = build(:user, password: "Password!!!!", password_confirmation: "Password!!!!")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("должен содержать хотя бы одну цифру")
    end

    it "запрещает пароль без спецсимвола" do
      user = build(:user, password: "Password1234", password_confirmation: "Password1234")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("должен содержать хотя бы один специальный символ")
    end

    it "запрещает кириллицу и нестандартный Unicode" do
      user = build(:user, password: "Password123!я", password_confirmation: "Password123!я")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("может содержать только латинские буквы, цифры и разрешённые специальные символы")
    end
  end
end
