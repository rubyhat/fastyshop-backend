FactoryBot.define do
  factory :cart_item do
    association :cart
    product { association :product, shop: cart.shop }
    quantity { 1 }
    price_snapshot { product.price }
  end
end
