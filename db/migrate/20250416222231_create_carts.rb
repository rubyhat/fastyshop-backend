class CreateCarts < ActiveRecord::Migration[8.0]
  def change
    create_table :carts, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :shop, null: false, foreign_key: true, type: :uuid
      t.datetime :expired_at, null: true

      t.timestamps
    end

    add_index :carts, %i[user_id shop_id], unique: true
  end
end
