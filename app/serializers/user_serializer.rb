class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :phone, :role, :country_code, :is_active
end
