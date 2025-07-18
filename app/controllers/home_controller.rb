class HomeController < ApplicationController
  def root
  end

  def main
    @move_ins = Lease.where("occupancy_dates && daterange(?, ?)", Date.current.prev_month.beginning_of_month, Date.current.prev_month.end_of_month).count
    last_month_move_ins = Lease.where("occupancy_dates && daterange(?, ?)", Date.current.prev_month.prev_month.beginning_of_month, Date.current.prev_month.prev_month.end_of_month).count
    @move_ins_percent = @move_ins > 0 ? ((@move_ins - last_month_move_ins).to_f / last_month_move_ins * 100).round(2) : 0

    total_to_date = 0
    current_month_points = (1..Date.current.prev_month.end_of_month.day).map do |day|
      {
        date: Date.current.prev_month.change(day: day),
        value: total_to_date += Lease.where("lower(occupancy_dates) = ?", Date.current.prev_month.change(day: day)).count
      }
    end
    total_to_date = 0
    last_month_points = (1..Date.current.prev_month.prev_month.end_of_month.day).map do |day|
      {
        date: Date.current.prev_month.prev_month.change(day: day),
        value: total_to_date += Lease.where("lower(occupancy_dates) = ?", Date.current.prev_month.prev_month.change(day: day)).count
      }
    end

    @labels = current_month_points.map { |p| p[:date].strftime("%Y-%m-%d") }
    @current_values = current_month_points.map { |p| p[:value] }
    @last_values = last_month_points.map { |p| p[:value] }
  end
end
