module Admin
  class DashboardController < BaseController
    def index
      @overview = Admin::Overview.call
    end
  end
end
