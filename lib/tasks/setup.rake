namespace :redcap2omop do
  namespace :setup do
    desc "OMOP tables"
    task(omop_tables: :environment) do |t, args|
      Redcap2omop::OmopTable.delete_all
      Redcap2omop::OmopColumn.delete_all
      Redcap2omop::Setup.omop_tables
    end
  end
end
