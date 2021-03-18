class AddFieldTypeCuratedToRedcapVariables < ActiveRecord::Migration[6.1]
  def change
    add_column :redcap2omop_redcap_variables, :field_type_curated, :string
  end
end
