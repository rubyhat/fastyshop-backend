require "rails_helper"

RSpec.describe Cart, type: :model do
  it "defaults to active status" do
    cart = create(:cart)

    expect(cart).to be_active
  end

  it "does not allow second active cart for same user and shop" do
    cart = create(:cart)
    duplicate = build(:cart, user: cart.user, shop: cart.shop)

    expect(duplicate).to be_invalid
    expect(duplicate.errors[:shop_id]).to include("Уже есть активная корзина для этого магазина")
  end

  it "allows new active cart after previous one was converted" do
    cart = create(:cart, :converted)
    replacement = build(:cart, user: cart.user, shop: cart.shop)

    expect(replacement).to be_valid
  end
end
