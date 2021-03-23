module SpecSetup
  def self.teardown
    keep_tables = %w[drug_strength concept concept_relationship concept_ancestor concept_synonym vocabulary relationship concept_class domain schema_migrations]

    ActiveRecord::Base.connection.tables.each do |table|
      unless keep_tables.include?(table)
        ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table} CASCADE;")
      end
    end
  end
end
