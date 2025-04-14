# frozen_string_literal: true

class ProductPropertySerializer < ActiveModel::Serializer
  attributes :id, :title, :value_type, :source_type, :user_id, :created_at, :updated_at
end
