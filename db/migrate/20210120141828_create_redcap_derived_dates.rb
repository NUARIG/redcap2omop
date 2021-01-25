class CreateRedcapDerivedDates < ActiveRecord::Migration[6.0]
  def change
    create_table :redcap_derived_dates do |t|
      t.integer :base_date_redcap_varaible_id,   null: false
      t.integer :offset_redcap_varaible_id,   null: false
      t.timestamps
    end
  end
end