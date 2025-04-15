require 'rails_helper'

RSpec.describe "Health", type: :request do
  describe "GET /status" do
    it "возвращает 200 OK" do
      get "/status"
      expect(response).to have_http_status(:ok)
    end
  end
end
