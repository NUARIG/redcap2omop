class CreateRedcapProjects < ActiveRecord::Migration[6.0]
  def change
    create_table :redcap_projects do |t|
      t.integer :project_id,  null: false
      t.string  :name,        null: false
      t.string  :api_token,   null: false
      t.timestamps
      t.datetime :deleted_at, null: true
    end
  end
end