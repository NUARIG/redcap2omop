class AddParentRedcapDerivedDateIdToRedcapDerivedDates < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap_derived_dates, :parent_redcap_derived_date_id, :integer, null: true
  end
end


