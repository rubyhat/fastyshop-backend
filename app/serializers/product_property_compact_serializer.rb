# frozen_string_literal: true

class ProductPropertyCompactSerializer < ActiveModel::Serializer
  attributes :id, :title, :value_type, :source_type, :user_id
end
