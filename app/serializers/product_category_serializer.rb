# frozen_string_literal: true

class ProductCategorySerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :slug,
             :level,
             :position,
             :status,
             :parent_id,
             :shop_id,
             :published_at,
             :published_by_id,
             :archived_at,
             :archived_by_id

  has_many :children, serializer: ProductCategorySerializer
end
