class AddFieldTypeCuratedToRedcapVariables < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap_variables, :field_type_curated, :string
  end
end
