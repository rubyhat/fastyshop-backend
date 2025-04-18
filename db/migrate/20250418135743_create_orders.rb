class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid, null: false
      t.references :shop, foreign_key: true, type: :uuid, null: false

      t.integer :status, null: false, default: 0
      t.integer :delivery_method, null: false
      t.integer :payment_method, null: false

      t.decimal :total_price, precision: 10, scale: 2, null: false

      t.string :contact_name, null: false
      t.string :contact_phone, null: false
      t.string :delivery_address_text, null: false
      t.string :delivery_comment
      t.string :status_comment

      t.boolean :canceled_by_user, default: false

      t.timestamps
    end
    add_index :orders, :status
    add_index :orders, [ :user_id, :status ]
    add_index :orders, [ :shop_id, :status ]
    add_index :orders, :created_at
  end
end
