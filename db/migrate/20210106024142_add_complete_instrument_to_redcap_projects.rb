class AddCompleteInstrumentToRedcapProjects < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap_projects, :complete_instrument, :boolean, null: false, default: false
  end
end
