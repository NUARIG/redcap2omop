require 'rails_helper'

RSpec.describe Redcap2omop::DictionaryServices::CsvImport do
  describe 'parsing dictionary from CSV file' do
    let(:project) { FactoryBot.create(:redcap_project) }
    let(:import) {
      Redcap2omop::DictionaryServices::CsvImport.new(
        redcap_project: project,
        csv_file: 'spec/support/data/test_dictionary.csv',
        csv_file_options: { headers: true, col_sep: ",", return_headers: false}
      )
    }
    describe 'when import is successful' do
      it 'creates new dictionary' do
        expect{ import.run }.to change{ Redcap2omop::RedcapDataDictionary.count }.by(1)
        expect(Redcap2omop::RedcapDataDictionary.last.redcap_project).to eq project
      end

      it 'creates redcap variables' do
        expect(Redcap2omop::RedcapVariable.count).to eq 0
        expect{ import.run }.to change{ Redcap2omop::RedcapVariable.count }.by(18)
        Redcap2omop::RedcapVariable.all.each do |redcap_variable|
          expect(redcap_variable.redcap_data_dictionary.redcap_project).to eq project
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

      it 'returns success' do
        expect(import.run.success).to eq true
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
