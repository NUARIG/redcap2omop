class CreateRedcapSourceLinks < ActiveRecord::Migration[6.0]
  def change
    create_table :redcap_source_links do |t|
      t.string :redcap_source_type
      t.integer :redcap_source_id
      t.string :redcap_sourced_type
      t.integer :redcap_sourced_id
      t.timestamps
    end
  end
end
