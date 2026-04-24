# frozen_string_literal: true

class ProductSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :slug,
             :description,
             :price,
             :product_type,
             :position,
             :status,
             :availability,
             :sku,
             :image_url,
             :shop_id,
             :product_category_id,
             :stock_quantity,
             :published_at,
             :published_by_id,
             :archived_at,
             :archived_by_id,
             :created_at,
             :updated_at

  has_many :product_property_values, serializer: ProductPropertyValueSerializer
end
