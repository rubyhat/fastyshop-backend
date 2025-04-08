class UserSerializer < ActiveModel::Serializer
  attributes :id, :phone, :role, :country_code, :is_active

  attribute :email, if: :show_email?

  def show_email?
    current_user = scope || instance_options[:current_user]
    current_user&.superadmin? || current_user&.supermanager? || current_user&.id == object.id
  end
end
