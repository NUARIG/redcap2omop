class AddRouteToObservationToRedcapProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :redcap2omop_redcap_projects, :route_to_observation, :boolean
  end
end
