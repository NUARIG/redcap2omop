class CreateRedcapExportTmp20201117100213 < ActiveRecord::Migration[6.0]
  def change
    connection.execute 'drop table if exists redcap_export_tmps'
    create_table :redcap_export_tmps do |t|
      t.string :record_id
			t.string :redcap_event_name
			t.string :redcap_repeat_instrument
			t.string :redcap_repeat_instance
			t.string :first_name
			t.string :last_name
			t.string :dob
			t.string :gender
			t.string :race___1
			t.string :race___2
			t.string :race___3
			t.string :race___4
			t.string :race___5
			t.string :race___6
			t.string :race___99
			t.string :ethnicity
			t.string :demographics_complete
			t.string :v_d
			t.string :v_coordinator
			t.string :visit_information_complete
			t.string :moca
			t.string :mood
			t.string :test_calc
			t.string :visit_data_complete
			t.string :m_d
			t.string :mri_coordinator
			t.string :mri_information_complete

      t.timestamps
    end
  end
end
