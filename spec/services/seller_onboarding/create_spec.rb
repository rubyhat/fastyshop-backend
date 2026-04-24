require "rails_helper"

RSpec.describe SellerOnboarding::Create do
  let!(:country) do
    Country.find_or_create_by!(code: "KZ") do |record|
      record.name = "Казахстан"
      record.phone_prefix = "+7"
    end
  end

  let(:user) { create(:user, role: :user) }
  let(:shop_category) { create(:shop_category) }

  let(:seller_profile_attributes) do
    {
      display_name: "Miras Group",
      description: "Seller description",
      logo_url: "https://cdn.example.com/logo.png"
    }
  end

  let(:legal_profile_attributes) do
    {
      country_code: "KZ",
      legal_form_code: "limited_liability_partnership",
      legal_name: "TOO Miras Group",
      registration_number_type: "bin",
      registration_number: "123456789012",
      legal_address: "Алматы, Абая 1"
    }
  end

  let(:shop_attributes) do
    {
      title: "Miras Flowers",
      slug: "miras-flowers",
      description: "Магазин цветов с доставкой",
      logo_url: "https://cdn.example.com/shops/miras-flowers.png",
      contact_phone: "+77001234567",
      contact_email: "shop@example.com",
      physical_address: "Алматы, Байзакова 10",
      shop_type: "online",
      shop_category_id: shop_category.id
    }
  end

  it "creates seller profile, legal profile and shop in one transaction" do
    result = described_class.new(
      user: user,
      seller_profile_attributes: seller_profile_attributes,
      legal_profile_attributes: legal_profile_attributes,
      shop_attributes: shop_attributes
    ).call

    expect(result).to be_success
    expect(result.seller_profile).to be_persisted
    expect(result.legal_profile).to be_persisted
    expect(result.shop).to be_persisted
    expect(user.reload.role).to eq("seller")
  end

  it "rolls back all entities when shop is invalid" do
    result = described_class.new(
      user: user,
      seller_profile_attributes: seller_profile_attributes,
      legal_profile_attributes: legal_profile_attributes,
      shop_attributes: shop_attributes.merge(title: nil)
    ).call

    expect(result).not_to be_success
    expect(user.reload.seller_profile).to be_nil
    expect(LegalProfile.count).to eq(0)
    expect(Shop.count).to eq(0)
    expect(user.role).to eq("user")
  end

  it "rolls back all entities when legal profile is invalid" do
    result = described_class.new(
      user: user,
      seller_profile_attributes: seller_profile_attributes,
      legal_profile_attributes: legal_profile_attributes.merge(country_code: "RU"),
      shop_attributes: shop_attributes
    ).call

    expect(result).not_to be_success
    expect(result.error_record).to be_a(LegalProfile)
    expect(result.error_record.errors[:country_code]).to include("страна временно не поддерживается для продавцов")
    expect(user.reload.seller_profile).to be_nil
    expect(LegalProfile.count).to eq(0)
    expect(Shop.count).to eq(0)
    expect(user.role).to eq("user")
  end

  it "returns a friendly business error when seller profile already exists" do
    create(:seller_profile, user: user)

    result = described_class.new(
      user: user,
      seller_profile_attributes: seller_profile_attributes,
      legal_profile_attributes: legal_profile_attributes,
      shop_attributes: shop_attributes
    ).call

    expect(result).not_to be_success
    expect(result.error_record).to eq(user.seller_profile)
    expect(result.error_record.errors[:base]).to include("Профиль продавца уже существует")
  end
end
