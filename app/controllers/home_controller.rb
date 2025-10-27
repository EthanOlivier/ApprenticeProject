class HomeController < ApplicationController
  def root
  end

  def main
    report_month = Date.current.prev_month
    prior_month = report_month.prev_month

    # Move Ins and Move Outs
    @report_month_move_ins = Lease.where("lower(occupancy_dates) >= ? AND lower(occupancy_dates) <= ?",
                      report_month.beginning_of_month,
                      report_month.end_of_month).count
    prior_month_move_in_leases = Lease.where("lower(occupancy_dates) >= ? AND lower(occupancy_dates) <= ?",
                      prior_month.beginning_of_month,
                      prior_month.end_of_month).to_a

    prior_month_move_ins = prior_month_move_in_leases.count

    @report_month_move_outs = Lease.where("upper(occupancy_dates) >= ? AND upper(occupancy_dates) <= ?",
                                report_month.beginning_of_month,
                                report_month.end_of_month).count
    prior_month_move_outs = Lease.where("upper(occupancy_dates) >= ? AND upper(occupancy_dates) <= ?",
                                prior_month.beginning_of_month,
                                prior_month.end_of_month).count



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



    @reportMonthName = report_month.strftime("%B")
    @priorMonthName = prior_month.strftime("%B")

    @move_ins_percent = prior_month_move_ins == 0 && @report_month_move_ins > 0 ? 100 :
                        prior_month_move_ins == 0 && @report_month_move_ins == 0 ? 0 :
                        ((@report_month_move_ins - prior_month_move_ins).to_f / prior_month_move_ins.abs * 100).round(2)
    @move_outs_percent = prior_month_move_outs == 0 && @report_month_move_outs > 0 ? 100 :
                        prior_month_move_outs == 0 && @report_month_move_outs == 0 ? 0 :
                        ((@report_month_move_outs - prior_month_move_outs).to_f / prior_month_move_outs.abs * 100).round(2)

    @report_month_days_labels = report_month_move_ins_points.map { |p| p[:date].strftime("%b %d") }
    @report_month_move_in_values = report_month_move_ins_points.map { |p| p[:value] }
    @prior_month_move_in_values = prior_month_move_ins_points.map { |p| p[:value] }

    @report_month_move_out_values = report_month_move_outs_points.map { |p| p[:value] }
    @prior_month_move_out_values = prior_month_move_outs_points.map { |p| p[:value] }




    # New Customers and Returning Customers
    @previous_months_new_customers, @previous_months_returning_customers, @month_labels = [], [], []

    (0..11).each do |months_back|
      target_month = report_month.months_ago(months_back)
      target_month_move_in_leases = Lease.where("lower(occupancy_dates) >= ? AND lower(occupancy_dates) <= ?",
                        target_month.beginning_of_month,
                        target_month.end_of_month).to_a

      new_customers_count = 0
      returning_customers_count = 0

      target_month_move_in_leases.each do |lease|
        if target_month.all_month.cover?(lease.customer.leases.minimum(Arel.sql("lower(occupancy_dates)")))
          new_customers_count += 1
        else
          returning_customers_count += 1
        end
      end

      @previous_months_new_customers.unshift(new_customers_count)
      @previous_months_returning_customers.unshift(returning_customers_count)

      @month_labels.unshift(target_month.strftime("%b \u2019%y"))
    end



    # Occupancy Rates
    days = (report_month.beginning_of_month..report_month.end_of_month).to_a

    @occupied = Array.new(days.length, 0)
    @vacant = Array.new(days.length, 0)
    @reserved = Array.new(days.length, 0)

    units = StorageUnit.where(company_id: 1).pluck(:id, :disabled)

    disabled_units, non_disabled_units = units.partition { |_, is_disabled| is_disabled }

    @disabled = Array.new(days.length, disabled_units.count)

    non_disabled_units = non_disabled_units.map(&:first).to_set

    # Example: { 1 => [[1, Date('2024-09-01'), Date('2024-10-01')]],
    #            3 => [[3, Date('2024-08-15'), nil], [3, Date('2024-11-01'), nil]] }
    leases = Lease.where(storage_unit_id: units.map(&:first), void: false)
                  .pluck(:storage_unit_id, Arel.sql("lower(occupancy_dates)"), Arel.sql("upper(occupancy_dates)"))
                  .group_by(&:first)

    days.each_with_index do |day, index|
      non_disabled_units.each do |unit_id|
        unit_lease_data = leases[unit_id] || []

        is_occupied = unit_lease_data.any? do |_, start_date, end_date|
          start_date <= day && (end_date.nil? || end_date > day || end_date == Float::INFINITY)
        end

        if is_occupied
          @occupied[index] += 1
        else
          is_reserved = unit_lease_data.any? { |_, start_date, _| start_date > day }

          if is_reserved
            @reserved[index] += 1
          else
            @vacant[index] += 1
          end
        end
      end
    end
  end
end
