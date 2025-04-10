class CreateShops < ActiveRecord::Migration[8.0]
  def change
    create_table :shops, id: :uuid do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :contact_phone, null: false
      t.string :contact_email
      t.string :physical_address
      t.boolean :is_active, null: false, default: true
      t.integer :shop_type, null: false

      t.uuid :seller_profile_id, null: false
      t.uuid :legal_profile_id, null: false
      t.uuid :shop_category_id, null: false

      t.timestamps
    end

    add_index :shops, :slug, unique: true
    add_index :shops, :is_active
    add_index :shops, :shop_type
    add_index :shops, :seller_profile_id
    add_index :shops, :legal_profile_id
    add_index :shops, :shop_category_id
  end
end
