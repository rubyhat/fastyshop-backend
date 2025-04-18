class CreateCartItems < ActiveRecord::Migration[8.0]
  def change
    create_table :cart_items, id: :uuid do |t|
      t.references :cart, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid
      t.integer :quantity, null: false
      t.decimal :price_snapshot, null: false, precision: 10, scale: 2

      t.timestamps
    end

    add_index :cart_items, %i[cart_id product_id], unique: true
  end
end
