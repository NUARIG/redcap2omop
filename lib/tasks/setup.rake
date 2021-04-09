namespace :redcap2omop do
  namespace :setup do
    desc "OMOP tables"
    task(omop_tables: :environment) do |t, args|
      Redcap2omop::OmopTable.delete_all
      Redcap2omop::OmopColumn.delete_all

      [Redcap2omop::ConditionOccurrence,
       Redcap2omop::Death,
       Redcap2omop::DeviceExposure,
       Redcap2omop::Measurement,
       Redcap2omop::Person,
       Redcap2omop::ProcedureOccurrence,
       Redcap2omop::Provider,
       Redcap2omop::Observation,
       Redcap2omop::VisitOccurrence
      ].map(&:setup_omop_table)
    end
  end
end
