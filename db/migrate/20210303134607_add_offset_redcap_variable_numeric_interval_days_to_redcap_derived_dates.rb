class AddOffsetRedcapVariableNumericIntervalDaysToRedcapDerivedDates < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap_derived_dates, :offset_redcap_variable_numeric_interval_days, :integer, null: true
  end
end
