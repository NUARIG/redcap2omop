# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_03_03_134607) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attribute_definition", primary_key: "attribute_definition_id", id: :integer, default: nil, force: :cascade do |t|
    t.string "attribute_name", limit: 255, null: false
    t.text "attribute_description"
    t.integer "attribute_type_concept_id", null: false
    t.text "attribute_syntax"
    t.index ["attribute_definition_id"], name: "idx_attribute_definition_id"
  end

  create_table "care_site", primary_key: "care_site_id", id: :integer, default: nil, force: :cascade do |t|
    t.string "care_site_name", limit: 255
    t.integer "place_of_service_concept_id"
    t.integer "location_id"
    t.string "care_site_source_value", limit: 50
    t.string "place_of_service_source_value", limit: 50
  end

  create_table "cdm_source", id: false, force: :cascade do |t|
    t.string "cdm_source_name", limit: 255, null: false
    t.string "cdm_source_abbreviation", limit: 25
    t.string "cdm_holder", limit: 255
    t.text "source_description"
    t.string "source_documentation_reference", limit: 255
    t.string "cdm_etl_reference", limit: 255
    t.date "source_release_date"
    t.date "cdm_release_date"
    t.string "cdm_version", limit: 10
    t.string "vocabulary_version", limit: 20
  end

  create_table "cohort", primary_key: ["cohort_definition_id", "subject_id", "cohort_start_date", "cohort_end_date"], force: :cascade do |t|
    t.integer "cohort_definition_id", null: false
    t.integer "subject_id", null: false
    t.date "cohort_start_date", null: false
    t.date "cohort_end_date", null: false
    t.index ["cohort_definition_id"], name: "idx_cohort_c_definition_id"
    t.index ["subject_id"], name: "idx_cohort_subject_id"
  end

  create_table "cohort_attribute", primary_key: ["cohort_definition_id", "subject_id", "cohort_start_date", "cohort_end_date", "attribute_definition_id"], force: :cascade do |t|
    t.integer "cohort_definition_id", null: false
    t.integer "subject_id", null: false
    t.date "cohort_start_date", null: false
    t.date "cohort_end_date", null: false
    t.integer "attribute_definition_id", null: false
    t.decimal "value_as_number"
    t.integer "value_as_concept_id"
    t.index ["cohort_definition_id"], name: "idx_ca_definition_id"
    t.index ["subject_id"], name: "idx_ca_subject_id"
  end

  create_table "cohort_definition", primary_key: "cohort_definition_id", id: :integer, default: nil, force: :cascade do |t|
    t.string "cohort_definition_name", limit: 255, null: false
    t.text "cohort_definition_description"
    t.integer "definition_type_concept_id", null: false
    t.text "cohort_definition_syntax"
    t.integer "subject_concept_id", null: false
    t.date "cohort_initiation_date"
    t.index ["cohort_definition_id"], name: "idx_cohort_definition_id"
  end

  create_table "concept", primary_key: "concept_id", id: :integer, default: nil, force: :cascade do |t|
    t.string "concept_name", limit: 255, null: false
    t.string "domain_id", limit: 20, null: false
    t.string "vocabulary_id", limit: 20, null: false
    t.string "concept_class_id", limit: 20, null: false
    t.string "standard_concept", limit: 1
    t.string "concept_code", limit: 50, null: false
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
    t.index ["concept_class_id"], name: "idx_concept_class_id"
    t.index ["concept_code"], name: "idx_concept_code"
    t.index ["concept_id"], name: "idx_concept_concept_id", unique: true
    t.index ["domain_id"], name: "idx_concept_domain_id"
    t.index ["vocabulary_id"], name: "idx_concept_vocabluary_id"
  end

  create_table "concept_ancestor", primary_key: ["ancestor_concept_id", "descendant_concept_id"], force: :cascade do |t|
    t.integer "ancestor_concept_id", null: false
    t.integer "descendant_concept_id", null: false
    t.integer "min_levels_of_separation", null: false
    t.integer "max_levels_of_separation", null: false
    t.index ["ancestor_concept_id"], name: "idx_concept_ancestor_id_1"
    t.index ["descendant_concept_id"], name: "idx_concept_ancestor_id_2"
  end

  create_table "concept_class", primary_key: "concept_class_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "concept_class_name", limit: 255, null: false
    t.integer "concept_class_concept_id", null: false
    t.index ["concept_class_id"], name: "idx_concept_class_class_id", unique: true
  end

  create_table "concept_relationship", primary_key: ["concept_id_1", "concept_id_2", "relationship_id"], force: :cascade do |t|
    t.integer "concept_id_1", null: false
    t.integer "concept_id_2", null: false
    t.string "relationship_id", limit: 20, null: false
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
    t.index ["concept_id_1"], name: "idx_concept_relationship_id_1"
    t.index ["concept_id_2"], name: "idx_concept_relationship_id_2"
    t.index ["relationship_id"], name: "idx_concept_relationship_id_3"
  end

  create_table "concept_synonym", id: false, force: :cascade do |t|
    t.integer "concept_id", null: false
    t.string "concept_synonym_name", limit: 1000, null: false
    t.integer "language_concept_id", null: false
    t.index ["concept_id", "concept_synonym_name", "language_concept_id"], name: "uq_concept_synonym", unique: true
    t.index ["concept_id"], name: "idx_concept_synonym_id"
  end

  create_table "condition_era", primary_key: "condition_era_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "condition_concept_id", null: false
    t.date "condition_era_start_date", null: false
    t.date "condition_era_end_date", null: false
    t.integer "condition_occurrence_count"
    t.index ["condition_concept_id"], name: "idx_condition_era_concept_id"
    t.index ["person_id"], name: "idx_condition_era_person_id"
  end

  create_table "condition_occurrence", primary_key: "condition_occurrence_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "condition_concept_id", null: false
    t.date "condition_start_date", null: false
    t.datetime "condition_start_datetime"
    t.date "condition_end_date"
    t.datetime "condition_end_datetime"
    t.integer "condition_type_concept_id", null: false
    t.string "stop_reason", limit: 20
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "condition_source_value", limit: 50
    t.integer "condition_source_concept_id"
    t.string "condition_status_source_value", limit: 50
    t.integer "condition_status_concept_id"
    t.index ["condition_concept_id"], name: "idx_condition_concept_id"
    t.index ["person_id"], name: "idx_condition_person_id"
    t.index ["visit_occurrence_id"], name: "idx_condition_visit_id"
  end

  create_table "cost", primary_key: "cost_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "cost_event_id", null: false
    t.string "cost_domain_id", limit: 20, null: false
    t.integer "cost_type_concept_id", null: false
    t.integer "currency_concept_id"
    t.decimal "total_charge"
    t.decimal "total_cost"
    t.decimal "total_paid"
    t.decimal "paid_by_payer"
    t.decimal "paid_by_patient"
    t.decimal "paid_patient_copay"
    t.decimal "paid_patient_coinsurance"
    t.decimal "paid_patient_deductible"
    t.decimal "paid_by_primary"
    t.decimal "paid_ingredient_cost"
    t.decimal "paid_dispensing_fee"
    t.integer "payer_plan_period_id"
    t.decimal "amount_allowed"
    t.integer "revenue_code_concept_id"
    t.string "reveue_code_source_value", limit: 50
    t.integer "drg_concept_id"
    t.string "drg_source_value", limit: 3
  end

  create_table "death", primary_key: "person_id", id: :integer, default: nil, force: :cascade do |t|
    t.date "death_date", null: false
    t.datetime "death_datetime"
    t.integer "death_type_concept_id", null: false
    t.integer "cause_concept_id"
    t.string "cause_source_value", limit: 50
    t.integer "cause_source_concept_id"
    t.index ["person_id"], name: "idx_death_person_id"
  end

  create_table "device_exposure", primary_key: "device_exposure_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "device_concept_id", null: false
    t.date "device_exposure_start_date", null: false
    t.datetime "device_exposure_start_datetime"
    t.date "device_exposure_end_date"
    t.datetime "device_exposure_end_datetime"
    t.integer "device_type_concept_id", null: false
    t.string "unique_device_id", limit: 50
    t.integer "quantity"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "device_source_value", limit: 100
    t.integer "device_source_concept_id"
    t.index ["device_concept_id"], name: "idx_device_concept_id"
    t.index ["person_id"], name: "idx_device_person_id"
    t.index ["visit_occurrence_id"], name: "idx_device_visit_id"
  end

  create_table "domain", primary_key: "domain_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "domain_name", limit: 255, null: false
    t.integer "domain_concept_id", null: false
    t.index ["domain_id"], name: "idx_domain_domain_id", unique: true
  end

  create_table "dose_era", primary_key: "dose_era_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "drug_concept_id", null: false
    t.integer "unit_concept_id", null: false
    t.decimal "dose_value", null: false
    t.date "dose_era_start_date", null: false
    t.date "dose_era_end_date", null: false
    t.index ["drug_concept_id"], name: "idx_dose_era_concept_id"
    t.index ["person_id"], name: "idx_dose_era_person_id"
  end

  create_table "drug_era", primary_key: "drug_era_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "drug_concept_id", null: false
    t.date "drug_era_start_date", null: false
    t.date "drug_era_end_date", null: false
    t.integer "drug_exposure_count"
    t.integer "gap_days"
    t.index ["drug_concept_id"], name: "idx_drug_era_concept_id"
    t.index ["person_id"], name: "idx_drug_era_person_id"
  end

  create_table "drug_exposure", primary_key: "drug_exposure_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "drug_concept_id", null: false
    t.date "drug_exposure_start_date", null: false
    t.datetime "drug_exposure_start_datetime"
    t.date "drug_exposure_end_date", null: false
    t.datetime "drug_exposure_end_datetime"
    t.date "verbatim_end_date"
    t.integer "drug_type_concept_id", null: false
    t.string "stop_reason", limit: 20
    t.integer "refills"
    t.decimal "quantity"
    t.integer "days_supply"
    t.text "sig"
    t.integer "route_concept_id"
    t.string "lot_number", limit: 50
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "drug_source_value", limit: 50
    t.integer "drug_source_concept_id"
    t.string "route_source_value", limit: 50
    t.string "dose_unit_source_value", limit: 50
    t.index ["drug_concept_id"], name: "idx_drug_concept_id"
    t.index ["person_id"], name: "idx_drug_person_id"
    t.index ["visit_occurrence_id"], name: "idx_drug_visit_id"
  end

  create_table "drug_strength", primary_key: ["drug_concept_id", "ingredient_concept_id"], force: :cascade do |t|
    t.integer "drug_concept_id", null: false
    t.integer "ingredient_concept_id", null: false
    t.decimal "amount_value"
    t.integer "amount_unit_concept_id"
    t.decimal "numerator_value"
    t.integer "numerator_unit_concept_id"
    t.decimal "denominator_value"
    t.integer "denominator_unit_concept_id"
    t.integer "box_size"
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
    t.index ["drug_concept_id"], name: "idx_drug_strength_id_1"
    t.index ["ingredient_concept_id"], name: "idx_drug_strength_id_2"
  end

  create_table "fact_relationship", id: false, force: :cascade do |t|
    t.integer "domain_concept_id_1", null: false
    t.integer "fact_id_1", null: false
    t.integer "domain_concept_id_2", null: false
    t.integer "fact_id_2", null: false
    t.integer "relationship_concept_id", null: false
    t.index ["domain_concept_id_1"], name: "idx_fact_relationship_id_1"
    t.index ["domain_concept_id_2"], name: "idx_fact_relationship_id_2"
    t.index ["relationship_concept_id"], name: "idx_fact_relationship_id_3"
  end

  create_table "location", primary_key: "location_id", id: :integer, default: nil, force: :cascade do |t|
    t.string "address_1", limit: 50
    t.string "address_2", limit: 50
    t.string "city", limit: 50
    t.string "state", limit: 2
    t.string "zip", limit: 9
    t.string "county", limit: 20
    t.string "location_source_value", limit: 50
  end

  create_table "measurement", primary_key: "measurement_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "measurement_concept_id", null: false
    t.date "measurement_date", null: false
    t.datetime "measurement_datetime"
    t.string "measurement_time", limit: 10
    t.integer "measurement_type_concept_id", null: false
    t.integer "operator_concept_id"
    t.decimal "value_as_number"
    t.integer "value_as_concept_id"
    t.integer "unit_concept_id"
    t.decimal "range_low"
    t.decimal "range_high"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "measurement_source_value", limit: 50
    t.integer "measurement_source_concept_id"
    t.string "unit_source_value", limit: 50
    t.string "value_source_value", limit: 50
    t.index ["measurement_concept_id"], name: "idx_measurement_concept_id"
    t.index ["person_id"], name: "idx_measurement_person_id"
    t.index ["visit_occurrence_id"], name: "idx_measurement_visit_id"
  end

  create_table "metadata", id: false, force: :cascade do |t|
    t.integer "metadata_concept_id", null: false
    t.integer "metadata_type_concept_id", null: false
    t.string "name", limit: 250, null: false
    t.text "value_as_string"
    t.integer "value_as_concept_id"
    t.date "metadata_date"
    t.datetime "metadata_datetime"
  end

  create_table "note", primary_key: "note_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.date "note_date", null: false
    t.datetime "note_datetime"
    t.integer "note_type_concept_id", null: false
    t.integer "note_class_concept_id", null: false
    t.string "note_title", limit: 250
    t.text "note_text"
    t.integer "encoding_concept_id", null: false
    t.integer "language_concept_id", null: false
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "note_source_value", limit: 50
    t.index ["note_type_concept_id"], name: "idx_note_concept_id"
    t.index ["person_id"], name: "idx_note_person_id"
    t.index ["visit_occurrence_id"], name: "idx_note_visit_id"
  end

  create_table "note_nlp", primary_key: "note_nlp_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "note_id", null: false
    t.integer "section_concept_id"
    t.string "snippet", limit: 250
    t.string "offset", limit: 250
    t.string "lexical_variant", limit: 250, null: false
    t.integer "note_nlp_concept_id"
    t.integer "note_nlp_source_concept_id"
    t.string "nlp_system", limit: 250
    t.date "nlp_date", null: false
    t.datetime "nlp_datetime"
    t.string "term_exists", limit: 1
    t.string "term_temporal", limit: 50
    t.string "term_modifiers", limit: 2000
    t.index ["note_id"], name: "idx_note_nlp_note_id"
    t.index ["note_nlp_concept_id"], name: "idx_note_nlp_concept_id"
  end

  create_table "observation", primary_key: "observation_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "observation_concept_id", null: false
    t.date "observation_date", null: false
    t.datetime "observation_datetime"
    t.integer "observation_type_concept_id", null: false
    t.decimal "value_as_number"
    t.string "value_as_string", limit: 60
    t.integer "value_as_concept_id"
    t.integer "qualifier_concept_id"
    t.integer "unit_concept_id"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "observation_source_value", limit: 50
    t.integer "observation_source_concept_id"
    t.string "unit_source_value", limit: 50
    t.string "qualifier_source_value", limit: 50
    t.string "value_source_value", limit: 50
    t.index ["observation_concept_id"], name: "idx_observation_concept_id"
    t.index ["person_id"], name: "idx_observation_person_id"
    t.index ["visit_occurrence_id"], name: "idx_observation_visit_id"
  end

  create_table "observation_period", primary_key: "observation_period_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.date "observation_period_start_date", null: false
    t.date "observation_period_end_date", null: false
    t.integer "period_type_concept_id", null: false
    t.index ["person_id"], name: "idx_observation_period_id"
  end

  create_table "omop_columns", force: :cascade do |t|
    t.integer "omop_table_id", null: false
    t.string "name", null: false
    t.string "data_type", null: false
    t.string "map_type", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "omop_tables", force: :cascade do |t|
    t.string "domain"
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "payer_plan_period", primary_key: "payer_plan_period_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.date "payer_plan_period_start_date", null: false
    t.date "payer_plan_period_end_date", null: false
    t.integer "payer_concept_id"
    t.string "payer_source_value", limit: 50
    t.integer "payer_source_concept_id"
    t.integer "plan_concept_id"
    t.string "plan_source_value", limit: 50
    t.integer "plan_source_concept_id"
    t.integer "sponsor_concept_id"
    t.string "sponsor_source_value", limit: 50
    t.integer "sponsor_source_concept_id"
    t.string "family_source_value", limit: 50
    t.integer "stop_reason_concept_id"
    t.string "stop_reason_source_value", limit: 50
    t.integer "stop_reason_source_concept_id"
    t.index ["person_id"], name: "idx_period_person_id"
  end

  create_table "person", primary_key: "person_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "gender_concept_id", null: false
    t.integer "year_of_birth", null: false
    t.integer "month_of_birth"
    t.integer "day_of_birth"
    t.datetime "birth_datetime"
    t.integer "race_concept_id", null: false
    t.integer "ethnicity_concept_id", null: false
    t.integer "location_id"
    t.integer "provider_id"
    t.integer "care_site_id"
    t.string "person_source_value", limit: 50
    t.string "gender_source_value", limit: 50
    t.integer "gender_source_concept_id"
    t.string "race_source_value", limit: 50
    t.integer "race_source_concept_id"
    t.string "ethnicity_source_value", limit: 50
    t.integer "ethnicity_source_concept_id"
    t.index ["person_id"], name: "idx_person_id", unique: true
  end

  create_table "procedure_occurrence", primary_key: "procedure_occurrence_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "procedure_concept_id", null: false
    t.date "procedure_date", null: false
    t.datetime "procedure_datetime"
    t.integer "procedure_type_concept_id", null: false
    t.integer "modifier_concept_id"
    t.integer "quantity"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "procedure_source_value", limit: 50
    t.integer "procedure_source_concept_id"
    t.string "modifier_source_value", limit: 50
    t.index ["person_id"], name: "idx_procedure_person_id"
    t.index ["procedure_concept_id"], name: "idx_procedure_concept_id"
    t.index ["visit_occurrence_id"], name: "idx_procedure_visit_id"
  end

  create_table "provider", primary_key: "provider_id", id: :integer, default: nil, force: :cascade do |t|
    t.string "provider_name", limit: 255
    t.string "npi", limit: 20
    t.string "dea", limit: 20
    t.integer "specialty_concept_id"
    t.integer "care_site_id"
    t.integer "year_of_birth"
    t.integer "gender_concept_id"
    t.string "provider_source_value", limit: 50
    t.string "specialty_source_value", limit: 50
    t.integer "specialty_source_concept_id"
    t.string "gender_source_value", limit: 50
    t.integer "gender_source_concept_id"
  end

  create_table "redcap_data_dictionaries", force: :cascade do |t|
    t.integer "redcap_project_id", null: false
    t.integer "version", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "redcap_derived_date_choice_offset_mappings", force: :cascade do |t|
    t.integer "redcap_derived_date_id", null: false
    t.integer "redcap_variable_choice_id", null: false
    t.integer "offset_days", null: false
  end

  create_table "redcap_derived_dates", force: :cascade do |t|
    t.integer "base_date_redcap_variable_id", null: false
    t.integer "offset_redcap_variable_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "parent_redcap_derived_date_id"
    t.integer "offset_redcap_variable_numeric_interval_days"
  end

  create_table "redcap_event_map_dependents", force: :cascade do |t|
    t.integer "redcap_variable_id", null: false
    t.integer "redcap_event_id", null: false
    t.integer "concept_id"
    t.integer "omop_column_id"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "redcap_event_maps", force: :cascade do |t|
    t.integer "redcap_event_id", null: false
    t.integer "concept_id"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "redcap_events", force: :cascade do |t|
    t.integer "redcap_data_dictionary_id", null: false
    t.string "event_name", null: false
    t.integer "arm_num", null: false
    t.integer "day_offset", null: false
    t.integer "offset_min", null: false
    t.integer "offset_max", null: false
    t.string "unique_event_name", null: false
    t.string "custom_event_label"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "redcap_projects", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "name", null: false
    t.string "api_token"
    t.string "export_table_name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.boolean "route_to_observation"
    t.boolean "insert_person"
    t.boolean "complete_instrument", default: false, null: false
    t.boolean "api_import"
  end

  create_table "redcap_records_tmp_1", id: false, force: :cascade do |t|
    t.string "record_id", limit: 255
    t.string "redcap_event_name", limit: 255
    t.string "redcap_repeat_instrument", limit: 255
    t.string "redcap_repeat_instance", limit: 255
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.string "dob", limit: 255
    t.string "gender", limit: 255
    t.string "race___1", limit: 255
    t.string "race___2", limit: 255
    t.string "race___3", limit: 255
    t.string "race___4", limit: 255
    t.string "race___5", limit: 255
    t.string "race___6", limit: 255
    t.string "race___99", limit: 255
    t.string "ethnicity", limit: 255
    t.string "hcw", limit: 255
    t.string "smoking_product___722495000", limit: 255
    t.string "smoking_product___unk", limit: 255
    t.string "smoking_product___oth", limit: 255
    t.string "smoking_product___722496004", limit: 255
    t.string "smoking_product___722498003", limit: 255
    t.string "smoking_product___722497008", limit: 255
    t.string "demographics_complete", limit: 255
    t.string "v_d", limit: 255
    t.string "v_coordinator", limit: 255
    t.string "visit_information_complete", limit: 255
    t.string "moca", limit: 255
    t.string "mood", limit: 255
    t.string "test_calc", limit: 255
    t.string "clock_position_of_wound", limit: 255
    t.string "visit_data_complete", limit: 255
    t.string "m_d", limit: 255
    t.string "mri_coordinator", limit: 255
    t.string "mri_information_complete", limit: 255
  end

  create_table "redcap_source_links", force: :cascade do |t|
    t.string "redcap_source_type"
    t.integer "redcap_source_id"
    t.string "redcap_sourced_type"
    t.integer "redcap_sourced_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "redcap_variable_child_maps", force: :cascade do |t|
    t.integer "redcap_variable_id"
    t.integer "parentable_id", null: false
    t.string "parentable_type", null: false
    t.integer "omop_column_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.string "map_type", null: false
    t.integer "redcap_derived_date_id"
    t.integer "concept_id"
  end

  create_table "redcap_variable_choice_maps", force: :cascade do |t|
    t.integer "redcap_variable_choice_id", null: false
    t.integer "concept_id"
    t.integer "omop_column_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.string "map_type", null: false
  end

  create_table "redcap_variable_choices", force: :cascade do |t|
    t.integer "redcap_variable_id", null: false
    t.string "choice_code_raw", null: false
    t.string "choice_code_concept_code"
    t.string "choice_description", null: false
    t.string "vocabulary_id_raw"
    t.string "vocabulary_id"
    t.string "map_choice"
    t.string "choice_code_value_as_concept_code"
    t.string "value_as_vocabualry_id"
    t.decimal "ordinal_position", null: false
    t.string "curation_status", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "redcap_variable_maps", force: :cascade do |t|
    t.integer "redcap_variable_id", null: false
    t.integer "concept_id"
    t.integer "omop_column_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.string "map_type", null: false
  end

  create_table "redcap_variables", force: :cascade do |t|
    t.integer "redcap_data_dictionary_id", null: false
    t.string "name", null: false
    t.string "form_name", null: false
    t.string "field_type", null: false
    t.string "field_type_normalized", null: false
    t.text "field_label", null: false
    t.text "choices"
    t.string "text_validation_type"
    t.string "field_annotation"
    t.decimal "ordinal_position"
    t.string "curation_status", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.string "field_type_curated"
  end

  create_table "relationship", primary_key: "relationship_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "relationship_name", limit: 255, null: false
    t.string "is_hierarchical", limit: 1, null: false
    t.string "defines_ancestry", limit: 1, null: false
    t.string "reverse_relationship_id", limit: 20, null: false
    t.integer "relationship_concept_id", null: false
    t.index ["relationship_id"], name: "idx_relationship_rel_id", unique: true
  end

  create_table "source_to_concept_map", primary_key: ["source_vocabulary_id", "target_concept_id", "source_code", "valid_end_date"], force: :cascade do |t|
    t.string "source_code", limit: 50, null: false
    t.integer "source_concept_id", null: false
    t.string "source_vocabulary_id", limit: 20, null: false
    t.string "source_code_description", limit: 255
    t.integer "target_concept_id", null: false
    t.string "target_vocabulary_id", limit: 20, null: false
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
    t.index ["source_code"], name: "idx_source_to_concept_map_code"
    t.index ["source_vocabulary_id"], name: "idx_source_to_concept_map_id_1"
    t.index ["target_concept_id"], name: "idx_source_to_concept_map_id_3"
    t.index ["target_vocabulary_id"], name: "idx_source_to_concept_map_id_2"
  end

  create_table "specimen", primary_key: "specimen_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "specimen_concept_id", null: false
    t.integer "specimen_type_concept_id", null: false
    t.date "specimen_date", null: false
    t.datetime "specimen_datetime"
    t.decimal "quantity"
    t.integer "unit_concept_id"
    t.integer "anatomic_site_concept_id"
    t.integer "disease_status_concept_id"
    t.string "specimen_source_id", limit: 50
    t.string "specimen_source_value", limit: 50
    t.string "unit_source_value", limit: 50
    t.string "anatomic_site_source_value", limit: 50
    t.string "disease_status_source_value", limit: 50
    t.index ["person_id"], name: "idx_specimen_person_id"
    t.index ["specimen_concept_id"], name: "idx_specimen_concept_id"
  end

  create_table "visit_detail", primary_key: "visit_detail_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "visit_detail_concept_id", null: false
    t.date "visit_detail_start_date", null: false
    t.datetime "visit_detail_start_datetime"
    t.date "visit_detail_end_date", null: false
    t.datetime "visit_detail_end_datetime"
    t.integer "visit_detail_type_concept_id", null: false
    t.integer "provider_id"
    t.integer "care_site_id"
    t.integer "admitting_source_concept_id"
    t.integer "discharge_to_concept_id"
    t.integer "preceding_visit_detail_id"
    t.string "visit_detail_source_value", limit: 50
    t.integer "visit_detail_source_concept_id"
    t.string "admitting_source_value", limit: 50
    t.string "discharge_to_source_value", limit: 50
    t.integer "visit_detail_parent_id"
    t.integer "visit_occurrence_id", null: false
    t.index ["person_id"], name: "idx_visit_detail_person_id"
    t.index ["visit_detail_concept_id"], name: "idx_visit_detail_concept_id"
  end

  create_table "visit_occurrence", primary_key: "visit_occurrence_id", id: :integer, default: nil, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "visit_concept_id", null: false
    t.date "visit_start_date", null: false
    t.datetime "visit_start_datetime"
    t.date "visit_end_date", null: false
    t.datetime "visit_end_datetime"
    t.integer "visit_type_concept_id", null: false
    t.integer "provider_id"
    t.integer "care_site_id"
    t.string "visit_source_value", limit: 50
    t.integer "visit_source_concept_id"
    t.integer "admitting_source_concept_id"
    t.string "admitting_source_value", limit: 50
    t.integer "discharge_to_concept_id"
    t.string "discharge_to_source_value", limit: 50
    t.integer "preceding_visit_occurrence_id"
    t.index ["person_id"], name: "idx_visit_person_id"
    t.index ["visit_concept_id"], name: "idx_visit_concept_id"
  end

  create_table "vocabulary", primary_key: "vocabulary_id", id: :string, limit: 20, force: :cascade do |t|
    t.string "vocabulary_name", limit: 255, null: false
    t.string "vocabulary_reference", limit: 255, null: false
    t.string "vocabulary_version", limit: 255
    t.integer "vocabulary_concept_id", null: false
    t.index ["vocabulary_id"], name: "idx_vocabulary_vocabulary_id", unique: true
  end

  add_foreign_key "attribute_definition", "concept", column: "attribute_type_concept_id", primary_key: "concept_id", name: "fpk_attribute_type_concept"
  add_foreign_key "care_site", "concept", column: "place_of_service_concept_id", primary_key: "concept_id", name: "fpk_care_site_place"
  add_foreign_key "care_site", "location", primary_key: "location_id", name: "fpk_care_site_location"
  add_foreign_key "cohort_attribute", "attribute_definition", primary_key: "attribute_definition_id", name: "fpk_ca_attribute_definition"
  add_foreign_key "cohort_attribute", "cohort_definition", primary_key: "cohort_definition_id", name: "fpk_ca_cohort_definition"
  add_foreign_key "cohort_attribute", "concept", column: "value_as_concept_id", primary_key: "concept_id", name: "fpk_ca_value"
  add_foreign_key "cohort_definition", "concept", column: "definition_type_concept_id", primary_key: "concept_id", name: "fpk_cohort_definition_concept"
  add_foreign_key "cohort_definition", "concept", column: "subject_concept_id", primary_key: "concept_id", name: "fpk_cohort_subject_concept"
  add_foreign_key "concept", "concept_class", primary_key: "concept_class_id", name: "fpk_concept_class"
  add_foreign_key "concept", "domain", primary_key: "domain_id", name: "fpk_concept_domain"
  add_foreign_key "concept", "vocabulary", primary_key: "vocabulary_id", name: "fpk_concept_vocabulary"
  add_foreign_key "concept_ancestor", "concept", column: "ancestor_concept_id", primary_key: "concept_id", name: "fpk_concept_ancestor_concept_1"
  add_foreign_key "concept_ancestor", "concept", column: "descendant_concept_id", primary_key: "concept_id", name: "fpk_concept_ancestor_concept_2"
  add_foreign_key "concept_class", "concept", column: "concept_class_concept_id", primary_key: "concept_id", name: "fpk_concept_class_concept"
  add_foreign_key "concept_relationship", "concept", column: "concept_id_1", primary_key: "concept_id", name: "fpk_concept_relationship_c_1"
  add_foreign_key "concept_relationship", "concept", column: "concept_id_2", primary_key: "concept_id", name: "fpk_concept_relationship_c_2"
  add_foreign_key "concept_relationship", "relationship", primary_key: "relationship_id", name: "fpk_concept_relationship_id"
  add_foreign_key "concept_synonym", "concept", column: "language_concept_id", primary_key: "concept_id", name: "fpk_concept_synonym_language"
  add_foreign_key "concept_synonym", "concept", primary_key: "concept_id", name: "fpk_concept_synonym_concept"
  add_foreign_key "condition_era", "concept", column: "condition_concept_id", primary_key: "concept_id", name: "fpk_condition_era_concept"
  add_foreign_key "condition_era", "person", primary_key: "person_id", name: "fpk_condition_era_person"
  add_foreign_key "condition_occurrence", "concept", column: "condition_concept_id", primary_key: "concept_id", name: "fpk_condition_concept"
  add_foreign_key "condition_occurrence", "concept", column: "condition_source_concept_id", primary_key: "concept_id", name: "fpk_condition_concept_s"
  add_foreign_key "condition_occurrence", "concept", column: "condition_status_concept_id", primary_key: "concept_id", name: "fpk_condition_status_concept"
  add_foreign_key "condition_occurrence", "concept", column: "condition_type_concept_id", primary_key: "concept_id", name: "fpk_condition_type_concept"
  add_foreign_key "condition_occurrence", "person", primary_key: "person_id", name: "fpk_condition_person"
  add_foreign_key "condition_occurrence", "provider", primary_key: "provider_id", name: "fpk_condition_provider"
  add_foreign_key "condition_occurrence", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_condition_visit"
  add_foreign_key "cost", "concept", column: "currency_concept_id", primary_key: "concept_id", name: "fpk_visit_cost_currency"
  add_foreign_key "cost", "concept", column: "drg_concept_id", primary_key: "concept_id", name: "fpk_drg_concept"
  add_foreign_key "cost", "payer_plan_period", primary_key: "payer_plan_period_id", name: "fpk_visit_cost_period"
  add_foreign_key "death", "concept", column: "cause_concept_id", primary_key: "concept_id", name: "fpk_death_cause_concept"
  add_foreign_key "death", "concept", column: "cause_source_concept_id", primary_key: "concept_id", name: "fpk_death_cause_concept_s"
  add_foreign_key "death", "concept", column: "death_type_concept_id", primary_key: "concept_id", name: "fpk_death_type_concept"
  add_foreign_key "death", "person", primary_key: "person_id", name: "fpk_death_person"
  add_foreign_key "device_exposure", "concept", column: "device_concept_id", primary_key: "concept_id", name: "fpk_device_concept"
  add_foreign_key "device_exposure", "concept", column: "device_source_concept_id", primary_key: "concept_id", name: "fpk_device_concept_s"
  add_foreign_key "device_exposure", "concept", column: "device_type_concept_id", primary_key: "concept_id", name: "fpk_device_type_concept"
  add_foreign_key "device_exposure", "person", primary_key: "person_id", name: "fpk_device_person"
  add_foreign_key "device_exposure", "provider", primary_key: "provider_id", name: "fpk_device_provider"
  add_foreign_key "device_exposure", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_device_visit"
  add_foreign_key "domain", "concept", column: "domain_concept_id", primary_key: "concept_id", name: "fpk_domain_concept"
  add_foreign_key "dose_era", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_dose_era_concept"
  add_foreign_key "dose_era", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_dose_era_unit_concept"
  add_foreign_key "dose_era", "person", primary_key: "person_id", name: "fpk_dose_era_person"
  add_foreign_key "drug_era", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_drug_era_concept"
  add_foreign_key "drug_era", "person", primary_key: "person_id", name: "fpk_drug_era_person"
  add_foreign_key "drug_exposure", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_drug_concept"
  add_foreign_key "drug_exposure", "concept", column: "drug_source_concept_id", primary_key: "concept_id", name: "fpk_drug_concept_s"
  add_foreign_key "drug_exposure", "concept", column: "drug_type_concept_id", primary_key: "concept_id", name: "fpk_drug_type_concept"
  add_foreign_key "drug_exposure", "concept", column: "route_concept_id", primary_key: "concept_id", name: "fpk_drug_route_concept"
  add_foreign_key "drug_exposure", "person", primary_key: "person_id", name: "fpk_drug_person"
  add_foreign_key "drug_exposure", "provider", primary_key: "provider_id", name: "fpk_drug_provider"
  add_foreign_key "drug_exposure", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_drug_visit"
  add_foreign_key "drug_strength", "concept", column: "amount_unit_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_unit_1"
  add_foreign_key "drug_strength", "concept", column: "denominator_unit_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_unit_3"
  add_foreign_key "drug_strength", "concept", column: "drug_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_concept_1"
  add_foreign_key "drug_strength", "concept", column: "ingredient_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_concept_2"
  add_foreign_key "drug_strength", "concept", column: "numerator_unit_concept_id", primary_key: "concept_id", name: "fpk_drug_strength_unit_2"
  add_foreign_key "fact_relationship", "concept", column: "domain_concept_id_1", primary_key: "concept_id", name: "fpk_fact_domain_1"
  add_foreign_key "fact_relationship", "concept", column: "domain_concept_id_2", primary_key: "concept_id", name: "fpk_fact_domain_2"
  add_foreign_key "fact_relationship", "concept", column: "relationship_concept_id", primary_key: "concept_id", name: "fpk_fact_relationship"
  add_foreign_key "measurement", "concept", column: "measurement_concept_id", primary_key: "concept_id", name: "fpk_measurement_concept"
  add_foreign_key "measurement", "concept", column: "measurement_source_concept_id", primary_key: "concept_id", name: "fpk_measurement_concept_s"
  add_foreign_key "measurement", "concept", column: "measurement_type_concept_id", primary_key: "concept_id", name: "fpk_measurement_type_concept"
  add_foreign_key "measurement", "concept", column: "operator_concept_id", primary_key: "concept_id", name: "fpk_measurement_operator"
  add_foreign_key "measurement", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_measurement_unit"
  add_foreign_key "measurement", "concept", column: "value_as_concept_id", primary_key: "concept_id", name: "fpk_measurement_value"
  add_foreign_key "measurement", "person", primary_key: "person_id", name: "fpk_measurement_person"
  add_foreign_key "measurement", "provider", primary_key: "provider_id", name: "fpk_measurement_provider"
  add_foreign_key "measurement", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_measurement_visit"
  add_foreign_key "note", "concept", column: "encoding_concept_id", primary_key: "concept_id", name: "fpk_note_encoding_concept"
  add_foreign_key "note", "concept", column: "language_concept_id", primary_key: "concept_id", name: "fpk_language_concept"
  add_foreign_key "note", "concept", column: "note_class_concept_id", primary_key: "concept_id", name: "fpk_note_class_concept"
  add_foreign_key "note", "concept", column: "note_type_concept_id", primary_key: "concept_id", name: "fpk_note_type_concept"
  add_foreign_key "note", "person", primary_key: "person_id", name: "fpk_note_person"
  add_foreign_key "note", "provider", primary_key: "provider_id", name: "fpk_note_provider"
  add_foreign_key "note", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_note_visit"
  add_foreign_key "note_nlp", "concept", column: "note_nlp_concept_id", primary_key: "concept_id", name: "fpk_note_nlp_concept"
  add_foreign_key "note_nlp", "concept", column: "section_concept_id", primary_key: "concept_id", name: "fpk_note_nlp_section_concept"
  add_foreign_key "note_nlp", "note", primary_key: "note_id", name: "fpk_note_nlp_note"
  add_foreign_key "observation", "concept", column: "observation_concept_id", primary_key: "concept_id", name: "fpk_observation_concept"
  add_foreign_key "observation", "concept", column: "observation_source_concept_id", primary_key: "concept_id", name: "fpk_observation_concept_s"
  add_foreign_key "observation", "concept", column: "observation_type_concept_id", primary_key: "concept_id", name: "fpk_observation_type_concept"
  add_foreign_key "observation", "concept", column: "qualifier_concept_id", primary_key: "concept_id", name: "fpk_observation_qualifier"
  add_foreign_key "observation", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_observation_unit"
  add_foreign_key "observation", "concept", column: "value_as_concept_id", primary_key: "concept_id", name: "fpk_observation_value"
  add_foreign_key "observation", "person", primary_key: "person_id", name: "fpk_observation_person"
  add_foreign_key "observation", "provider", primary_key: "provider_id", name: "fpk_observation_provider"
  add_foreign_key "observation", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_observation_visit"
  add_foreign_key "observation_period", "concept", column: "period_type_concept_id", primary_key: "concept_id", name: "fpk_observation_period_concept"
  add_foreign_key "observation_period", "person", primary_key: "person_id", name: "fpk_observation_period_person"
  add_foreign_key "payer_plan_period", "person", primary_key: "person_id", name: "fpk_payer_plan_period"
  add_foreign_key "person", "care_site", primary_key: "care_site_id", name: "fpk_person_care_site"
  add_foreign_key "person", "concept", column: "ethnicity_concept_id", primary_key: "concept_id", name: "fpk_person_ethnicity_concept"
  add_foreign_key "person", "concept", column: "ethnicity_source_concept_id", primary_key: "concept_id", name: "fpk_person_ethnicity_concept_s"
  add_foreign_key "person", "concept", column: "gender_concept_id", primary_key: "concept_id", name: "fpk_person_gender_concept"
  add_foreign_key "person", "concept", column: "gender_source_concept_id", primary_key: "concept_id", name: "fpk_person_gender_concept_s"
  add_foreign_key "person", "concept", column: "race_concept_id", primary_key: "concept_id", name: "fpk_person_race_concept"
  add_foreign_key "person", "concept", column: "race_source_concept_id", primary_key: "concept_id", name: "fpk_person_race_concept_s"
  add_foreign_key "person", "location", primary_key: "location_id", name: "fpk_person_location"
  add_foreign_key "person", "provider", primary_key: "provider_id", name: "fpk_person_provider"
  add_foreign_key "procedure_occurrence", "concept", column: "modifier_concept_id", primary_key: "concept_id", name: "fpk_procedure_modifier"
  add_foreign_key "procedure_occurrence", "concept", column: "procedure_concept_id", primary_key: "concept_id", name: "fpk_procedure_concept"
  add_foreign_key "procedure_occurrence", "concept", column: "procedure_source_concept_id", primary_key: "concept_id", name: "fpk_procedure_concept_s"
  add_foreign_key "procedure_occurrence", "concept", column: "procedure_type_concept_id", primary_key: "concept_id", name: "fpk_procedure_type_concept"
  add_foreign_key "procedure_occurrence", "person", primary_key: "person_id", name: "fpk_procedure_person"
  add_foreign_key "procedure_occurrence", "provider", primary_key: "provider_id", name: "fpk_procedure_provider"
  add_foreign_key "procedure_occurrence", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpk_procedure_visit"
  add_foreign_key "provider", "care_site", primary_key: "care_site_id", name: "fpk_provider_care_site"
  add_foreign_key "provider", "concept", column: "gender_concept_id", primary_key: "concept_id", name: "fpk_provider_gender"
  add_foreign_key "provider", "concept", column: "gender_source_concept_id", primary_key: "concept_id", name: "fpk_provider_gender_s"
  add_foreign_key "provider", "concept", column: "specialty_concept_id", primary_key: "concept_id", name: "fpk_provider_specialty"
  add_foreign_key "provider", "concept", column: "specialty_source_concept_id", primary_key: "concept_id", name: "fpk_provider_specialty_s"
  add_foreign_key "relationship", "concept", column: "relationship_concept_id", primary_key: "concept_id", name: "fpk_relationship_concept"
  add_foreign_key "relationship", "relationship", column: "reverse_relationship_id", primary_key: "relationship_id", name: "fpk_relationship_reverse"
  add_foreign_key "source_to_concept_map", "concept", column: "source_concept_id", primary_key: "concept_id", name: "fpk_source_concept_id"
  add_foreign_key "source_to_concept_map", "concept", column: "target_concept_id", primary_key: "concept_id", name: "fpk_source_to_concept_map_c_1"
  add_foreign_key "source_to_concept_map", "vocabulary", column: "source_vocabulary_id", primary_key: "vocabulary_id", name: "fpk_source_to_concept_map_v_1"
  add_foreign_key "source_to_concept_map", "vocabulary", column: "target_vocabulary_id", primary_key: "vocabulary_id", name: "fpk_source_to_concept_map_v_2"
  add_foreign_key "specimen", "concept", column: "anatomic_site_concept_id", primary_key: "concept_id", name: "fpk_specimen_site_concept"
  add_foreign_key "specimen", "concept", column: "disease_status_concept_id", primary_key: "concept_id", name: "fpk_specimen_status_concept"
  add_foreign_key "specimen", "concept", column: "specimen_concept_id", primary_key: "concept_id", name: "fpk_specimen_concept"
  add_foreign_key "specimen", "concept", column: "specimen_type_concept_id", primary_key: "concept_id", name: "fpk_specimen_type_concept"
  add_foreign_key "specimen", "concept", column: "unit_concept_id", primary_key: "concept_id", name: "fpk_specimen_unit_concept"
  add_foreign_key "specimen", "person", primary_key: "person_id", name: "fpk_specimen_person"
  add_foreign_key "visit_detail", "care_site", primary_key: "care_site_id", name: "fpk_v_detail_care_site"
  add_foreign_key "visit_detail", "concept", column: "admitting_source_concept_id", primary_key: "concept_id", name: "fpk_v_detail_admitting_s"
  add_foreign_key "visit_detail", "concept", column: "discharge_to_concept_id", primary_key: "concept_id", name: "fpk_v_detail_discharge"
  add_foreign_key "visit_detail", "concept", column: "visit_detail_source_concept_id", primary_key: "concept_id", name: "fpk_v_detail_concept_s"
  add_foreign_key "visit_detail", "concept", column: "visit_detail_type_concept_id", primary_key: "concept_id", name: "fpk_v_detail_type_concept"
  add_foreign_key "visit_detail", "person", primary_key: "person_id", name: "fpk_v_detail_person"
  add_foreign_key "visit_detail", "provider", primary_key: "provider_id", name: "fpk_v_detail_provider"
  add_foreign_key "visit_detail", "visit_detail", column: "preceding_visit_detail_id", primary_key: "visit_detail_id", name: "fpk_v_detail_preceding"
  add_foreign_key "visit_detail", "visit_detail", column: "visit_detail_parent_id", primary_key: "visit_detail_id", name: "fpk_v_detail_parent"
  add_foreign_key "visit_detail", "visit_occurrence", primary_key: "visit_occurrence_id", name: "fpd_v_detail_visit"
  add_foreign_key "visit_occurrence", "care_site", primary_key: "care_site_id", name: "fpk_visit_care_site"
  add_foreign_key "visit_occurrence", "concept", column: "admitting_source_concept_id", primary_key: "concept_id", name: "fpk_visit_admitting_s"
  add_foreign_key "visit_occurrence", "concept", column: "discharge_to_concept_id", primary_key: "concept_id", name: "fpk_visit_discharge"
  add_foreign_key "visit_occurrence", "concept", column: "visit_source_concept_id", primary_key: "concept_id", name: "fpk_visit_concept_s"
  add_foreign_key "visit_occurrence", "concept", column: "visit_type_concept_id", primary_key: "concept_id", name: "fpk_visit_type_concept"
  add_foreign_key "visit_occurrence", "person", primary_key: "person_id", name: "fpk_visit_person"
  add_foreign_key "visit_occurrence", "provider", primary_key: "provider_id", name: "fpk_visit_provider"
  add_foreign_key "visit_occurrence", "visit_occurrence", column: "preceding_visit_occurrence_id", primary_key: "visit_occurrence_id", name: "fpk_visit_preceding"
  add_foreign_key "vocabulary", "concept", column: "vocabulary_concept_id", primary_key: "concept_id", name: "fpk_vocabulary_concept"
end
