class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items, id: :uuid do |t|
      t.references :order, type: :uuid, null: false, index: true, foreign_key: true
      t.references :product, type: :uuid, null: false, index: true, foreign_key: true

      t.integer :quantity, null: false
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end
    add_index :order_items, %i[order_id product_id], unique: true
  end
end
