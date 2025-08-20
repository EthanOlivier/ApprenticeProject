class HomeController < ApplicationController
  def root
  end

  def main
    report_month = Date.current.prev_month
    prior_month = report_month.prev_month

    report_month_move_in_leases = Lease.where("lower(occupancy_dates) >= ? AND lower(occupancy_dates) <= ?",
                      report_month.beginning_of_month,
                      report_month.end_of_month).to_a
    prior_month_move_in_leases = Lease.where("lower(occupancy_dates) >= ? AND lower(occupancy_dates) <= ?",
                      prior_month.beginning_of_month,
                      prior_month.end_of_month).to_a

    @report_month_move_ins = report_month_move_in_leases.count
    prior_month_move_ins = prior_month_move_in_leases.count

    @report_month_move_outs = Lease.where("upper(occupancy_dates) >= ? AND upper(occupancy_dates) <= ?",
                                report_month.beginning_of_month,
                                report_month.end_of_month).count
    @move_ins_percent = @report_month_move_ins > 0 ? ((@report_month_move_ins - prior_month_move_ins).to_f / prior_month_move_ins * 100).round(2) : 0
    prior_month_move_outs = Lease.where("upper(occupancy_dates) >= ? AND upper(occupancy_dates) <= ?",
                                prior_month.beginning_of_month,
                                prior_month.end_of_month).count
    @move_outs_percent = @report_month_move_outs > 0 ? ((@report_month_move_outs - prior_month_move_outs).to_f / prior_month_move_outs * 100).round(2) : 0



    @report_month_new_customers, @report_month_existing_customers, @prior_month_new_customers, @prior_month_existing_customers = 0, 0, 0, 0
    report_month_move_in_leases.each do |lease|
      if report_month.all_month.cover?(lease.customer.leases.minimum(Arel.sql("lower(occupancy_dates)")))
        @report_month_new_customers += 1
      else
        @report_month_existing_customers += 1
      end
    end

    prior_month_move_in_leases.each do |lease|
      if prior_month.all_month.cover?(lease.customer.leases.minimum(Arel.sql("lower(occupancy_dates)")))
        @prior_month_new_customers += 1
      else
        @prior_month_existing_customers += 1
      end
    end



    report_month_move_ins_total_to_date = 0
    report_month_move_ins_points = (1..report_month.end_of_month.day).map do |day|
      {
        date: report_month.change(day: day),
        value: report_month_move_ins_total_to_date += Lease.where("lower(occupancy_dates) = ?", report_month.change(day: day)).count
      }
    end
    prior_month_move_ins_total_to_date = 0
    prior_month_move_ins_points = (1..prior_month.end_of_month.day).map do |day|
      {
        date: prior_month.change(day: day),
        value: prior_month_move_ins_total_to_date += Lease.where("lower(occupancy_dates) = ?", prior_month.change(day: day)).count
      }
    end

    report_month_move_outs_total_to_date = 0
    report_month_move_outs_points = (1..report_month.end_of_month.day).map do |day|
      {
        date: report_month.change(day: day),
        value: report_month_move_outs_total_to_date += Lease.where("upper(occupancy_dates) = ?", report_month.change(day: day)).count
      }
    end
    prior_month_move_outs_total_to_date = 0
    prior_month_move_outs_points = (1..prior_month.end_of_month.day).map do |day|
      {
        date: prior_month.change(day: day),
        value: prior_month_move_outs_total_to_date += Lease.where("upper(occupancy_dates) = ?", prior_month.change(day: day)).count
      }
    end

    @move_ins_and_outs_labels = report_month_move_ins_points.map { |p| p[:date].strftime("%Y-%m-%d") }
    @report_month_move_in_values = report_month_move_ins_points.map { |p| p[:value] }
    @prior_month_move_in_values = prior_month_move_ins_points.map { |p| p[:value] }

    @report_month_move_out_values = report_month_move_outs_points.map { |p| p[:value] }
    @prior_month_move_out_values = prior_month_move_outs_points.map { |p| p[:value] }
  end
end
