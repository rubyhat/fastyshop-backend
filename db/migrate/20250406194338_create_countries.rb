class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries, id: :uuid do |t|
      t.string :code, null: false          # например, "KZ"
      t.string :name, null: false          # например, "Казахстан"
      t.string :phone_prefix, null: false  # например, "+7"

      t.timestamps
    end

    add_index :countries, :code, unique: true
  end
end
