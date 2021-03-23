module Redcap2omop::WithOmopTable
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
    def setup_omop_table
      omop_table        = Redcap2omop::OmopTable.new
      omop_table.name   = self.table_name
      omop_table.domain = self.try(:domain)

      instance = self.new
      instance.attributes.keys.each do |attribute|
        omop_column = omop_table.omop_columns.build
        omop_column.name = attribute
        omop_column.data_type = self.column_for_attribute(attribute).type
        omop_column.map_type  = self.map_types[attribute.to_sym]
      end
      omop_table.save!
    end
  end
end
