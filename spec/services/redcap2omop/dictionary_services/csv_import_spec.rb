require 'rails_helper'

RSpec.describe Redcap2omop::DictionaryServices::CsvImport do
  describe 'parsing dictionary from CSV file' do
    let(:redcap_project) { FactoryBot.create(:redcap_project) }
    let(:import) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: redcap_project,
        csv_file: 'spec/support/data/test_dictionary.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }

    let(:import_data_dictionary_with_new_redcap_variable) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: redcap_project,
        csv_file: 'spec/support/data/test_dictionary_with_new_redcap_variable.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }

    let(:import_data_dictionary_with_redcap_variable_changed_field_type) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: redcap_project,
        csv_file: 'spec/support/data/test_dictionary_with_redcap_variable_changed_field_type.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }

    describe 'when import is successful' do
      it 'creates new dictionary', focus: false do
        expect{ import.run }.to change{ Redcap2omop::RedcapDataDictionary.count }.by(1)
        expect(Redcap2omop::RedcapDataDictionary.last.redcap_project).to eq redcap_project
      end

      it 'creates redcap variables' do
        expect(Redcap2omop::RedcapVariable.count).to eq 0
        expect{ import.run }.to change{ Redcap2omop::RedcapVariable.count }.by(18)
        Redcap2omop::RedcapVariable.all.each do |redcap_variable|
          expect(redcap_variable.redcap_data_dictionary.redcap_project).to eq redcap_project
        end
        variable = Redcap2omop::RedcapVariable.get_by_name('dob')
        expect(variable).not_to be_nil
        expect(variable.form_name).to eq 'demographics'
        expect(variable.field_type).to eq 'text'
        expect(variable.text_validation_type).to eq 'date_ymd'
        expect(variable.field_label).to eq 'Date of Birth'
        expect(variable.choices).to be_blank
        expect(variable.field_annotation).to be_blank

        variable = Redcap2omop::RedcapVariable.get_by_name('last_name')
        expect(variable).not_to be_nil
        expect(variable.form_name).to eq 'demographics'
        expect(variable.field_type).to eq 'text'
        expect(variable.text_validation_type).to be_blank
        expect(variable.field_label).to eq 'Last Name'
        expect(variable.choices).to be_blank
        expect(variable.field_annotation).to be_blank

        variable = Redcap2omop::RedcapVariable.get_by_name('gender')
        expect(variable).not_to be_nil
        expect(variable.form_name).to eq 'demographics'
        expect(variable.field_type).to eq 'radio'
        expect(variable.text_validation_type).to be_blank
        expect(variable.field_label).to eq 'Gender'
        expect(variable.choices).to eq "1, Cis Female | 2, Trans Female | 3, Cis Male | 4, Transe Male | 5, Non-binary"
        expect(variable.field_annotation).to be_blank
      end

      it 'returns success', focus: false do
        expect(import.run.success).to eq true
      end

      it 'does not create a new data dictionary if nothing changed', focus: false do
        import.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        import.run
        redcap_project.reload
        expect(redcap_project.current_redcap_data_dictionary).to eq redcap_data_dictionary
      end

      it 'does create a new data dictionary if new Redcap variable is added', focus: false do
        import.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        import_data_dictionary_with_new_redcap_variable.run
        redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
        expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'mri_coordinator2').first
        expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_NEW_VARIABLE
      end

      it "does create a new data dictionary if a Redcap variable's type is changed", focus: false do
        import.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        import_data_dictionary_with_redcap_variable_changed_field_type.run
        redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
        expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'moca').first
        expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_TYPE
      end
    end

    context 'when import fails' do
      before(:each) do
        allow_any_instance_of(Redcap2omop::RedcapVariable).to receive(:valid?).and_return(false)
      end

      it 'does not save new dictionary' do
        expect{ import.run }.not_to change{ Redcap2omop::RedcapDataDictionary.count }
      end

      it 'does not create redcap variables' do
        expect{ import.run }.not_to change{ Redcap2omop::RedcapVariable.count }
      end

      it 'returns exception' do
        result = import.run
        expect(result.success).to eq false
        expect(result.message).not_to be_blank
        expect(result.backtrace).not_to be_blank
      end
    end
  end
end
