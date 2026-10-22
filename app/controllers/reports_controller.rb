class ReportsController < ApplicationController
  def index
    @year = parse_year(params[:year])
    @years = available_years
    @report = Reports::Annual.call(user: current_user, year: @year)
  end

  private

  def parse_year(value)
    year = value.to_i
    year.between?(2000, Date.current.year + 1) ? year : Date.current.year
  end

  def available_years
    first = current_user.savings.minimum(:saved_on)&.year || Date.current.year
    (first..Date.current.year).to_a.reverse
  end
end
