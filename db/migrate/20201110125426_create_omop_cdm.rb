require './lib/redcap2omop/setup/setup'
class CreateOmopCdm < ActiveRecord::Migration[6.0]
  def change
    Redcap2omop::Setup.compile_omop_tables
    Redcap2omop::Setup.compile_omop_table_extensions
  end
end
