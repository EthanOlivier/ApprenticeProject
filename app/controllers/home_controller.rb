class HomeController < ApplicationController
  def root
  end

  def main
    @report_month_move_ins = Lease.where("lower(occupancy_dates) >= ? AND lower(occupancy_dates) <= ?",
                      Date.current.prev_month.beginning_of_month,
                      Date.current.prev_month.end_of_month).count
    prior_month_move_ins = Lease.where("lower(occupancy_dates) >= ? AND lower(occupancy_dates) <= ?",
                                Date.current.prev_month.prev_month.beginning_of_month,
                                Date.current.prev_month.prev_month.end_of_month).count
    @move_ins_percent = @report_month_move_ins > 0 ? ((@report_month_move_ins - prior_month_move_ins).to_f / prior_month_move_ins * 100).round(2) : 0

    @report_month_move_outs = Lease.where("upper(occupancy_dates) >= ? AND upper(occupancy_dates) <= ?",
                      Date.current.prev_month.beginning_of_month,
                      Date.current.prev_month.end_of_month).count
    prior_month_move_outs = Lease.where("upper(occupancy_dates) >= ? AND upper(occupancy_dates) <= ?",
                                Date.current.prev_month.prev_month.beginning_of_month,
                                Date.current.prev_month.prev_month.end_of_month).count
    @move_outs_percent = @report_month_move_outs > 0 ? ((@report_month_move_outs - prior_month_move_outs).to_f / prior_month_move_outs * 100).round(2) : 0



    report_month_move_ins_total_to_date = 0
    report_month_move_ins_points = (1..Date.current.prev_month.end_of_month.day).map do |day|
      {
        date: Date.current.prev_month.change(day: day),
        value: report_month_move_ins_total_to_date += Lease.where("lower(occupancy_dates) = ?", Date.current.prev_month.change(day: day)).count
      }
    end
    prior_month_move_ins_total_to_date = 0
    prior_month_move_ins_points = (1..Date.current.prev_month.prev_month.end_of_month.day).map do |day|
      {
        date: Date.current.prev_month.prev_month.change(day: day),
        value: prior_month_move_ins_total_to_date += Lease.where("lower(occupancy_dates) = ?", Date.current.prev_month.prev_month.change(day: day)).count
      }
    end

    report_month_move_outs_total_to_date = 0
    report_month_move_outs_points = (1..Date.current.prev_month.end_of_month.day).map do |day|
      {
        date: Date.current.prev_month.change(day: day),
        value: report_month_move_outs_total_to_date += Lease.where("upper(occupancy_dates) = ?", Date.current.prev_month.change(day: day)).count
      }
    end
    prior_month_move_outs_total_to_date = 0
    prior_month_move_outs_points = (1..Date.current.prev_month.prev_month.end_of_month.day).map do |day|
      {
        date: Date.current.prev_month.prev_month.change(day: day),
        value: prior_month_move_outs_total_to_date += Lease.where("upper(occupancy_dates) = ?", Date.current.prev_month.prev_month.change(day: day)).count
      }
    end



    @labels = report_month_move_ins_points.map { |p| p[:date].strftime("%Y-%m-%d") }
    @report_month_move_in_values = report_month_move_ins_points.map { |p| p[:value] }
    @prior_month_move_in_values = prior_month_move_ins_points.map { |p| p[:value] }

    @report_month_move_out_values = report_month_move_outs_points.map { |p| p[:value] }
    @prior_month_move_out_values = prior_month_move_outs_points.map { |p| p[:value] }
  end
end
