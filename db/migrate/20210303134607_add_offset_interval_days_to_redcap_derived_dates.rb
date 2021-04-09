class AddOffsetIntervalDaysToRedcapDerivedDates < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap2omop_redcap_derived_dates, :offset_interval_days, :integer, null: true
  end
end
