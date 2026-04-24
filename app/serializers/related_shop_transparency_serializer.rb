# frozen_string_literal: true

class RelatedShopTransparencySerializer < ActiveModel::Serializer
  attributes :id, :title, :slug, :verified_badge
end
