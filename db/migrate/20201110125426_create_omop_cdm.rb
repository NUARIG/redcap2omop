class CreateOmopCdm < ActiveRecord::Migration[6.1]
  def change
    Redcap2omop::Setup.compile_omop_tables
    Redcap2omop::Setup.compile_omop_table_extensions
  end
end
