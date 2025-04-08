class CreateSellerProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :seller_profiles, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :display_name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :logo_url

      t.timestamps
    end

    add_index :seller_profiles, :user_id, unique: true
    add_index :seller_profiles, :slug, unique: true
  end
end
