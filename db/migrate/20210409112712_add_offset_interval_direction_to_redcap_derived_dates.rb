class AddOffsetIntervalDirectionToRedcapDerivedDates < ActiveRecord::Migration[6.1]
  def change
    add_column :redcap2omop_redcap_derived_dates, :offset_interval_direction, :string, null: true
  end
end
