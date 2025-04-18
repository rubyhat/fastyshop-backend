# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order, type: :model do
  let(:user) { create(:user) }
  let(:shop) { create(:shop) }
  let(:order) do
    create(:order,
           user: user,
           shop: shop,
           status: :created,
           delivery_method: :courier,
           payment_method: :online,
           contact_name: "Тест",
           contact_phone: "77070000000",
           delivery_address_text: "Тестовый адрес",
           total_price: 1000
    )
  end

  before do
    Current.user = user
  end

  describe "статус заказа — допустимые переходы" do
    it "разрешает переход с created на accepted" do
      order.status = :accepted
      expect(order).to be_valid
    end

    it "разрешает переход с accepted на delivery_in_progress" do
      order.update!(status: :accepted)
      order.status = :delivery_in_progress
      expect(order).to be_valid
    end
  end

  describe "статус заказа — запрещённые переходы" do
    it "запрещает переход с accepted обратно на created" do
      order.update!(status: :accepted)
      order.status = :created

      expect(order.valid?).to be false
      expect(order.errors[:base]).to include("Нельзя изменить статус с accepted на created")
    end

    it "запрещает переход с created сразу на completed" do
      order.status = :completed

      expect(order.valid?).to be false
      expect(order.errors[:base]).to include("Нельзя изменить статус с created на completed")
    end
  end

  describe "отмена заказа покупателем" do
    it "разрешает отмену пользователем, который сделал заказ" do
      order.status = :canceled_by_user
      expect(order).to be_valid
    end

    it "запрещает отмену другим пользователем" do
      another_user = create(:user)
      Current.user = another_user

      order.status = :canceled_by_user
      expect(order).to be_invalid
      expect(order.errors[:base]).to include("Вы не можете отменить заказ от имени покупателя")
    end
  end
end
