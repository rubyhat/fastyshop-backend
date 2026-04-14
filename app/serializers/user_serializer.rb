class UserSerializer < ActiveModel::Serializer
  attributes :id, :role, :country_code, :account_status, :first_name, :last_name, :middle_name

  attribute :phone, if: :show_private_contact?
  attribute :phone_display, if: :show_private_contact?
  attribute :email, if: :show_email?

  def show_email?
    show_private_contact?
  end

  def show_private_contact?
    current_user = scope || instance_options[:current_user]
    current_user&.superadmin? || current_user&.supermanager? || current_user&.id == object.id
  end
end
