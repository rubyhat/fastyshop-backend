class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :phone, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.integer :role, null: false, default: 3
      t.string :country_code, null: false, default: "KZ"
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :users, :phone, unique: true
    add_index :users, :email, unique: true
  end
end
