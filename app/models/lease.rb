class Lease < ApplicationRecord
  validate :reject_next_bill_date_update_backwards_into_past
  validate :reject_occupancy_end_date_in_the_future
  validate :reject_next_bill_date_before_occupancy_starts
  validate :reject_overlapping_occupancy_on_storage_unit

  has_many :unsigned_agreements, -> { where(accepted_at: nil) }, class_name: "LeaseAgreementRequest"

  scope :void, -> { where(void: true) }
  scope :active, ->(today = Date.current) {
    where(void: false).where("occupancy_dates && daterange(?::date, null)", today)
  }
  scope :past, ->(today = Date.current) {
    where(void: false).where("occupancy_dates &< daterange(null, ?::date)", today.yesterday)
  }

  def storage_unit_name
    if storage_unit
      storage_unit.name
    elsif bulk_storage_unit
      bulk_storage_unit.name
    end
  end

  def location
    if storage_unit
      storage_unit.location
    elsif bulk_storage_unit
      bulk_storage_unit.location
    end
  end

  def unit
    if storage_unit_id
      storage_unit
    elsif bulk_storage_unit_id
      bulk_storage_unit
    end
  end

  def past?(date = Time.zone.today)
    occupancy_dates.end.present? && occupancy_dates.end != Float::INFINITY && occupancy_dates.end < date
  end

  def present_or_future?(date = Time.zone.today)
    !past?(date)
  end

  def select_label
    "##{serial_num} - #{storage_unit_name}"
  end

  def status
    if void?
      :void
    elsif past?
      :past
    else
      :active
    end
  end

  def active?
    status == :active
  end

  def first_bill_date_when_proration(occupancy_begins = Date.current, proration_day_of_month = 1)
    case billing_interval.value
    when BillingInterval::WEEKLY
      occupancy_begins.next_week.beginning_of_week
    when BillingInterval::MONTHLY
      if occupancy_begins.day >= proration_day_of_month
        max_day_of_next_month = (proration_day_of_month > occupancy_begins.next_month.end_of_month.day) ? occupancy_begins.next_month.end_of_month.day : proration_day_of_month
        next_date = occupancy_begins.next_month.beginning_of_month
        Date.new(next_date.year, next_date.month, max_day_of_next_month)
      else
        Date.new(occupancy_begins.year, occupancy_begins.month, proration_day_of_month)
      end
    when BillingInterval::DAILY
      occupancy_begins.tomorrow
    else
      occupancy_begins.next_month.beginning_of_month
    end
  end

  def prorated_bill_discount(occupancy_begins = Date.current, day_of_month = 1)
    days_in_billing_interval = billing_interval.to_duration.in_days.to_i

    return 0.0 if days_in_billing_interval < 30

    days_remaining = if billing_interval.value == BillingInterval::MONTHLY
      (first_bill_date_when_proration(occupancy_begins, day_of_month) - occupancy_begins).to_i
    else
      (occupancy_begins.next_month.beginning_of_month - occupancy_begins).to_i
    end

    amount_per_day = cash_price.fdiv(days_in_billing_interval)
    bill_amount = (days_remaining * amount_per_day).ceil
    [ -(cash_price - bill_amount), 0 ].min
  end

  def bulk_storage?
    bulk_storage_unit_id.present?
  end

  def pac_code_generation_queued?
    GoodJob::Job.queued
      .or(GoodJob::Job.scheduled)
      .or(GoodJob::Job.running)
      .where(concurrency_key: "#{AutoGenerateLeasePacCodeJob}-#{id}").exists?
  end

  private

  def reject_occupancy_end_date_in_the_future
    if occupancy_dates.end.present? && occupancy_dates.end != Float::INFINITY && occupancy_dates.end > Time.current.to_date
      errors.add :occupancy_ends, "cannot be in the future"
    end
  end

  def reject_overlapping_occupancy_on_storage_unit
    return if storage_unit_id.blank?

    conflicting_lease = self.class
      .where.not(id:)
      .where(storage_unit_id:, void: false)
      .where("occupancy_dates @> ?::date", occupancy_dates.begin)
      .first

    return if conflicting_lease.blank?

    range_to_text = ->(range) do
      range.end.infinite? ?
             "starting from #{range.begin}." :
             "from #{range.begin} to #{range.end}."
    end

    message = <<~TXT.squish
      "#{storage_unit.name}" already has a lease
      #{range_to_text.call(conflicting_lease.occupancy_dates)}
      You tried to save one #{range_to_text.call(occupancy_dates)}
    TXT

    errors.add(:storage_unit_id, message)
  end

  def reject_next_bill_date_before_occupancy_starts
    if occupancy_dates.begin > next_bill_date
      errors.add :next_bill_date, "cannot be before occupancy starts"
    end
  end

  def reject_next_bill_date_update_backwards_into_past
    if next_bill_date && next_bill_date_was && next_bill_date < next_bill_date_was && next_bill_date < Time.zone.today
      errors.add :next_bill_date, "cannot update backwards into past"
    end
  end

  # creates a CTE and joins to make the last paid invoice's due date available
  scope :with_last_invoice_paid_due_dates, ->(company) do
    cte_name = :last_invoice_paid_due_dates
    return self if with_values.any? { |cte| cte.key?(cte_name) }

    last_invoice_paid_due_dates_table = Arel::Table.new(cte_name)
    last_invoice_paid_due_dates_query = Lease.select("leases.id as lease_id, max(invoices.due_date) as due_date")
      .joins(invoice_items: :invoice)
      .merge(Invoice.paid)
      .where(company:)
      .group(:id)

    with(last_invoice_paid_due_dates: last_invoice_paid_due_dates_query)
      .joins(
        arel_table
          .join(last_invoice_paid_due_dates_table, Arel::Nodes::OuterJoin)
          .on(last_invoice_paid_due_dates_table[:lease_id].eq(arel_table[:id]))
          .join_sources
      )
  end

  # creates a CTE and joins to make the last rate change date available
  scope :with_last_rate_change_dates, ->(company) do
    cte_name = :last_rate_change_dates
    return self if with_values.any? { |cte| cte.key?(cte_name) }

    last_rate_change_dates_table = Arel::Table.new(cte_name)

    last_rate_change_dates_query = RateChange.select("distinct on (lease_id) lease_id, effective_date")
      .joins(:lease)
      .applied
      .where(leases: { company: })
      .order(lease_id: :asc, effective_date: :desc)

    with(last_rate_change_dates: last_rate_change_dates_query)
      .joins(
        arel_table
          .join(last_rate_change_dates_table, Arel::Nodes::OuterJoin)
          .on(last_rate_change_dates_table[:lease_id].eq(arel_table[:id]))
          .join_sources
      )
  end

  # creates a CTE and joins to make the scheduled rate change date available
  scope :with_scheduled_rate_change_dates, ->(company) do
    cte_name = :scheduled_rate_change_dates
    return self if with_values.any? { |cte| cte.key?(cte_name) }

    scheduled_rate_change_dates_table = Arel::Table.new(cte_name)

    scheduled_rate_change_dates_query = RateChange.select("distinct on (lease_id) lease_id, effective_date")
      .joins(:lease)
      .scheduled
      .where(leases: { company: })
      .order(:lease_id, :effective_date)

    with(scheduled_rate_change_dates: scheduled_rate_change_dates_query)
      .joins(
        arel_table
          .join(scheduled_rate_change_dates_table, Arel::Nodes::OuterJoin)
          .on(scheduled_rate_change_dates_table[:lease_id].eq(arel_table[:id]))
          .join_sources
      )
  end

  scope :with_latest_security_deposits, -> do
    sd_alias = "latest_security_deposits"
    already_joined = joins_values.any? do |j|
      j.is_a?(Arel::Nodes::Join) && j.left.is_a?(Arel::Nodes::TableAlias) && j.left.right.to_s == sd_alias
    end
    return self if already_joined

    sd_table = SecurityDeposit.arel_table
    aliased_lateral_subquery = Arel::Nodes::TableAlias.new(
      Arel::Nodes::Lateral.new(
        sd_table
          .project(sd_table[Arel.star])
          .where(sd_table[:lease_id].eq(arel_table[:id]))
          .order(sd_table[:collected_at].desc)
          .take(1)
      ),
      sd_alias
    )

    join_clause = Arel::Nodes::OuterJoin.new(aliased_lateral_subquery, Arel::Nodes::On.new(Arel.sql("true")))
    joins(join_clause)
  end
end
