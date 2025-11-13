class HomeController < ApplicationController
  def root
  end

  def main
    report_month = Date.current.prev_month
    prior_month = report_month.prev_month

    # Move Ins and Move Outs
    move_ins_and_outs_query_builder = -> (start_date:, end_date:) do
      ActiveRecord::Base.sanitize_sql_array([<<~SQL, { start_date:, end_date: }])
        with t as (
            select day::date,
            count(distinct move_in_leases.id) as move_in_count,
            count(distinct move_out_leases.id) as move_out_count
            from generate_series(:start_date::date, :end_date::date, interval '1 day') as day
            left join leases as move_in_leases on lower(move_in_leases.occupancy_dates) = day::date
            left join leases as move_out_leases on upper(move_out_leases.occupancy_dates) = day::date
            group by day
            order by day
        )
        select *,
            (sum(move_in_count) over (order by day rows between unbounded preceding and current row))::bigint as move_ins_total,
            (sum(move_out_count) over (order by day rows between unbounded preceding and current row))::bigint as move_outs_total
        from t
        ;
      SQL
    end

    report_month_query = move_ins_and_outs_query_builder.call(start_date: report_month.beginning_of_month.to_s, end_date: report_month.end_of_month.to_s)
    report_month_results = ActiveRecord::Base.connection.execute(report_month_query).to_a

    prior_month_query = move_ins_and_outs_query_builder.call(start_date: prior_month.beginning_of_month.to_s, end_date: prior_month.end_of_month.to_s)
    prior_month_results = ActiveRecord::Base.connection.execute(prior_month_query).to_a

    @report_month_day_labels = report_month_results.map { _1["day"].strftime("%b %d") }

    @reportMonthName = report_month.strftime("%B")
    @priorMonthName = prior_month.strftime("%B")


    @report_month_move_ins = report_month_results.last["move_ins_total"]
    prior_month_move_ins = prior_month_results.last["move_ins_total"]
    @report_month_move_outs = report_month_results.last["move_outs_total"]
    prior_month_move_outs = prior_month_results.last["move_outs_total"]

    @move_ins_percent = prior_month_move_ins == 0 && @report_month_move_ins > 0 ? 100 :
                        prior_month_move_ins == 0 && @report_month_move_ins == 0 ? 0 :
                        ((@report_month_move_ins - prior_month_move_ins).to_f / prior_month_move_ins.abs * 100).round(2)
    @move_outs_percent = prior_month_move_outs == 0 && @report_month_move_outs > 0 ? 100 :
                        prior_month_move_outs == 0 && @report_month_move_outs == 0 ? 0 :
                        ((@report_month_move_outs - prior_month_move_outs).to_f / prior_month_move_outs.abs * 100).round(2)

    @report_month_move_in_values = report_month_results.map { _1["move_ins_total"] }
    @prior_month_move_in_values = prior_month_results.map { _1["move_ins_total"] }
    @report_month_move_out_values = report_month_results.map { _1["move_outs_total"] }
    @prior_month_move_out_values = prior_month_results.map { _1["move_outs_total"] }



    # New Customers and Returning Customers
    new_and_returning_customers_query = ActiveRecord::Base.sanitize_sql_array([<<~SQL, { start_date: report_month.prev_month(11).beginning_of_month.to_s, end_date: report_month.end_of_month.to_s }])
      with
        month_series as (
          select 
            month::date as first_day,
            (month + interval '1 month' - interval '1 day')::date as last_day
          from generate_series('2024-11-01'::date, '2025-10-31'::date, interval '1 month') as month
        ),
        month_leases as (
          select 
            lower(occupancy_dates) as move_in_date,
            customer_id
          from leases
          where lower(occupancy_dates) >= '2024-11-01'::date and lower(occupancy_dates) <= '2025-10-31'::date
        ),
        customers_first_lease as (
          select 
            ml.customer_id,
            min(lower(l.occupancy_dates)) as move_in_date
          from month_leases as ml
          left join leases as l on ml.customer_id = l.customer_id
          group by ml.customer_id
        )
      select 
        ms.first_day as month,
        sum(case when cfl.move_in_date = ml.move_in_date then 1 else 0 end) as new_customer_move_in_count,
        sum(case when cfl.move_in_date != ml.move_in_date then 1 else 0 end) as returning_customer_move_in_count
      from month_series as ms
      left join month_leases as ml on ml.move_in_date >= ms.first_day and ml.move_in_date <= ms.last_day
      left join customers_first_lease as cfl on ml.customer_id = cfl.customer_id
      group by ms.first_day
      order by ms.first_day
      ;
    SQL

    new_and_returning_customers_report_results = ActiveRecord::Base.connection.execute(new_and_returning_customers_query).to_a

    @month_labels = new_and_returning_customers_report_results.map { _1["month"].strftime("%b \u2019%y") }
    @new_customers = new_and_returning_customers_report_results.map { _1["new_customer_move_in_count"] }
    @returning_customers = new_and_returning_customers_report_results.map { _1["returning_customer_move_in_count"] }



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
