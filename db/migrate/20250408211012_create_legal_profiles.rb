class CreateLegalProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :legal_profiles, id: :uuid do |t|
      t.uuid :seller_profile_id, null: false
      t.string :company_name, null: false
      t.string :tax_id, null: false
      t.string :country_code, null: false
      t.string :legal_address, null: false
      t.string :legal_form, null: false
      t.boolean :is_verified, default: false

      t.timestamps
    end

    add_index :legal_profiles, :tax_id, unique: true
    add_index :legal_profiles, :seller_profile_id
  end
end
