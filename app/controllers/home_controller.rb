class HomeController < ApplicationController
  def root
  end

  def main
    @move_ins = 123
    @move_ins_percent = 12

    total_to_date = 0
    current_month_points = (1..Date.parse("2025-03-01").end_of_month.day).map do |day|
      { date: Date.parse("2025-03-%02d" % day), value: total_to_date += rand(0..50) }
    end
    total_to_date = 0
    last_month_points = (1..Date.parse("2025-02-01").end_of_month.day).map do |day|
      { date: Date.parse("2025-02-%02d" % day), value: total_to_date += rand(0..50) }
    end

    @labels = current_month_points.map { |p| p[:date].strftime("%Y-%m-%d") }
    @current_values = current_month_points.map { |p| p[:value] }
    @last_values = last_month_points.map { |p| p[:value] }
  end
end
