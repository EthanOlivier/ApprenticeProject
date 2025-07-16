class HomeController < ApplicationController
  def root
  end

  def main
    @move_ins = 123
    @move_ins_percent = 12

    chart_points = [
      { date: Date.today - 4, value: 10 },
      { date: Date.today - 3, value: 15 },
      { date: Date.today - 2, value: 20 },
      { date: Date.today - 1, value: 17 },
      { date: Date.today,     value: 22 }
    ]
    @labels = chart_points.map { |p| p[:date].strftime("%Y-%m-%d") }
    @values = chart_points.map { |p| p[:value] }
  end
end
