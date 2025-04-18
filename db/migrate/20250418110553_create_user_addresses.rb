class CreateUserAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :user_addresses, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.string :label, null: false # Название адреса, например: Дом, офис и т.д.
      t.string :country_code, null: false
      t.string :city, null: false
      t.string :street, null: false
      t.string :house, null: false
      t.string :apartment
      t.string :postal_code
      t.string :contact_name, null: false
      t.string :contact_phone, null: false
      t.boolean :is_default, null: false, default: false
      t.string :description # Небольшой коммент об этом адресе, будет виден продавцу, клиент может указать какую-либо доп. информацию об этом адресе

      t.timestamps
    end
    add_index :user_addresses, %i[user_id is_default], unique: true, where: "is_default = true", name: "idx_one_default_address_per_user"
  end
end
