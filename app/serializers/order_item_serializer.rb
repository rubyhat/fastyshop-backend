# frozen_string_literal: true

class OrderItemSerializer < ActiveModel::Serializer
  attributes :quantity

  # Ручная сериализация продукта
  attribute :product_property do
    ProductCompactSerializer.new(object.product, scope: scope, root: false).as_json
  end
end
