/*********************************************************************************
# Copyright 2014 Observational Health Data Sciences and Informatics
#
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
********************************************************************************/

/************************

 ####### #     # ####### ######      #####  ######  #     #           #######      #####      #####
 #     # ##   ## #     # #     #    #     # #     # ##   ##    #    # #           #     #    #     #  ####  #    #  ####  ##### #####    ##   # #    # #####  ####
 #     # # # # # #     # #     #    #       #     # # # # #    #    # #                 #    #       #    # ##   # #        #   #    #  #  #  # ##   #   #   #
 #     # #  #  # #     # ######     #       #     # #  #  #    #    # ######       #####     #       #    # # #  #  ####    #   #    # #    # # # #  #   #    ####
 #     # #     # #     # #          #       #     # #     #    #    #       # ###       #    #       #    # #  # #      #   #   #####  ###### # #  # #   #        #
 #     # #     # #     # #          #     # #     # #     #     #  #  #     # ### #     #    #     # #    # #   ## #    #   #   #   #  #    # # #   ##   #   #    #
 ####### #     # ####### #           #####  ######  #     #      ##    #####  ###  #####      #####   ####  #    #  ####    #   #    # #    # # #    #   #    ####


postgresql script to create foreign key constraints within OMOP common data model, version 5.3.0

last revised: 14-June-2018

author:  Patrick Ryan, Clair Blacketer


*************************/


/************************
*************************
*************************
*************************

Foreign key constraints

*************************
*************************
*************************
************************/


/************************

Standardized vocabulary

************************/


ALTER TABLE concept DROP CONSTRAINT fpk_concept_domain;

ALTER TABLE concept DROP CONSTRAINT fpk_concept_class;

ALTER TABLE concept DROP CONSTRAINT fpk_concept_vocabulary;

ALTER TABLE vocabulary DROP CONSTRAINT fpk_vocabulary_concept;

ALTER TABLE domain DROP CONSTRAINT fpk_domain_concept;

ALTER TABLE concept_class DROP CONSTRAINT fpk_concept_class_concept;

ALTER TABLE concept_relationship DROP CONSTRAINT fpk_concept_relationship_c_1;

ALTER TABLE concept_relationship DROP CONSTRAINT fpk_concept_relationship_c_2;

ALTER TABLE concept_relationship DROP CONSTRAINT fpk_concept_relationship_id;

ALTER TABLE relationship DROP CONSTRAINT fpk_relationship_concept;

ALTER TABLE relationship DROP CONSTRAINT fpk_relationship_reverse;

ALTER TABLE concept_synonym DROP CONSTRAINT fpk_concept_synonym_concept;

ALTER TABLE concept_synonym DROP CONSTRAINT fpk_concept_synonym_language;

ALTER TABLE concept_ancestor DROP CONSTRAINT fpk_concept_ancestor_concept_1;

ALTER TABLE concept_ancestor DROP CONSTRAINT fpk_concept_ancestor_concept_2;

ALTER TABLE source_to_concept_map DROP CONSTRAINT fpk_source_to_concept_map_v_1;

ALTER TABLE source_to_concept_map DROP CONSTRAINT fpk_source_concept_id;

ALTER TABLE source_to_concept_map DROP CONSTRAINT fpk_source_to_concept_map_v_2;

ALTER TABLE source_to_concept_map DROP CONSTRAINT fpk_source_to_concept_map_c_1;

ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_concept_1;

ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_concept_2;

ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_unit_1;

ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_unit_2;

ALTER TABLE drug_strength DROP CONSTRAINT fpk_drug_strength_unit_3;

ALTER TABLE cohort_definition DROP CONSTRAINT fpk_cohort_definition_concept;

ALTER TABLE cohort_definition DROP CONSTRAINT fpk_cohort_subject_concept;

ALTER TABLE attribute_definition DROP CONSTRAINT fpk_attribute_type_concept;


/**************************

Standardized meta-data

***************************/





/************************

Standardized clinical data

************************/

ALTER TABLE person DROP CONSTRAINT fpk_person_gender_concept;

ALTER TABLE person DROP CONSTRAINT fpk_person_race_concept;

ALTER TABLE person DROP CONSTRAINT fpk_person_ethnicity_concept;

ALTER TABLE person DROP CONSTRAINT fpk_person_gender_concept_s;

ALTER TABLE person DROP CONSTRAINT fpk_person_race_concept_s;

ALTER TABLE person DROP CONSTRAINT fpk_person_ethnicity_concept_s;

ALTER TABLE person DROP CONSTRAINT fpk_person_location;

ALTER TABLE person DROP CONSTRAINT fpk_person_provider;

ALTER TABLE person DROP CONSTRAINT fpk_person_care_site;


ALTER TABLE observation_period DROP CONSTRAINT fpk_observation_period_person;

ALTER TABLE observation_period DROP CONSTRAINT fpk_observation_period_concept;


ALTER TABLE specimen DROP CONSTRAINT fpk_specimen_person;

ALTER TABLE specimen DROP CONSTRAINT fpk_specimen_concept;

ALTER TABLE specimen DROP CONSTRAINT fpk_specimen_type_concept;

ALTER TABLE specimen DROP CONSTRAINT fpk_specimen_unit_concept;

ALTER TABLE specimen DROP CONSTRAINT fpk_specimen_site_concept;

ALTER TABLE specimen DROP CONSTRAINT fpk_specimen_status_concept;


ALTER TABLE death DROP CONSTRAINT fpk_death_person;

ALTER TABLE death DROP CONSTRAINT fpk_death_type_concept;

ALTER TABLE death DROP CONSTRAINT fpk_death_cause_concept;

ALTER TABLE death DROP CONSTRAINT fpk_death_cause_concept_s;


ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_person;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_type_concept;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_provider;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_care_site;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_concept_s;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_admitting_s;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_discharge;

ALTER TABLE visit_occurrence DROP CONSTRAINT fpk_visit_preceding;


ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_person;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_type_concept;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_provider;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_care_site;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_concept_s;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_admitting_s;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_discharge;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_preceding;

ALTER TABLE visit_detail DROP CONSTRAINT fpk_v_detail_parent;

ALTER TABLE visit_detail DROP CONSTRAINT fpd_v_detail_visit;


ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_person;

ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_concept;

ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_type_concept;

ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_modifier;

ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_provider;

ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_visit;

ALTER TABLE procedure_occurrence DROP CONSTRAINT fpk_procedure_concept_s;


ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_person;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_concept;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_type_concept;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_route_concept;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_provider;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_visit;

ALTER TABLE drug_exposure DROP CONSTRAINT fpk_drug_concept_s;


ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_person;

ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_concept;

ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_type_concept;

ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_provider;

ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_visit;

ALTER TABLE device_exposure DROP CONSTRAINT fpk_device_concept_s;


ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_person;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_concept;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_type_concept;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_provider;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_visit;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_concept_s;

ALTER TABLE condition_occurrence DROP CONSTRAINT fpk_condition_status_concept;


ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_person;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_concept;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_type_concept;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_operator;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_value;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_unit;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_provider;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_visit;

ALTER TABLE measurement DROP CONSTRAINT fpk_measurement_concept_s;


ALTER TABLE note DROP CONSTRAINT fpk_note_person;

ALTER TABLE note DROP CONSTRAINT fpk_note_type_concept;

ALTER TABLE note DROP CONSTRAINT fpk_note_class_concept;

ALTER TABLE note DROP CONSTRAINT fpk_note_encoding_concept;

ALTER TABLE note DROP CONSTRAINT fpk_language_concept;

ALTER TABLE note DROP CONSTRAINT fpk_note_provider;

ALTER TABLE note DROP CONSTRAINT fpk_note_visit;


ALTER TABLE note_nlp DROP CONSTRAINT fpk_note_nlp_note;

ALTER TABLE note_nlp DROP CONSTRAINT fpk_note_nlp_section_concept;

ALTER TABLE note_nlp DROP CONSTRAINT fpk_note_nlp_concept;



ALTER TABLE observation DROP CONSTRAINT fpk_observation_person;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_concept;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_type_concept;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_value;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_qualifier;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_unit;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_provider;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_visit;

ALTER TABLE observation DROP CONSTRAINT fpk_observation_concept_s;


ALTER TABLE fact_relationship DROP CONSTRAINT fpk_fact_domain_1;

ALTER TABLE fact_relationship DROP CONSTRAINT fpk_fact_domain_2;

ALTER TABLE fact_relationship DROP CONSTRAINT fpk_fact_relationship;



/************************

Standardized health system data

************************/

ALTER TABLE care_site DROP CONSTRAINT fpk_care_site_location;

ALTER TABLE care_site DROP CONSTRAINT fpk_care_site_place;


ALTER TABLE provider DROP CONSTRAINT fpk_provider_specialty;

ALTER TABLE provider DROP CONSTRAINT fpk_provider_care_site;

ALTER TABLE provider DROP CONSTRAINT fpk_provider_gender;

ALTER TABLE provider DROP CONSTRAINT fpk_provider_specialty_s;

ALTER TABLE provider DROP CONSTRAINT fpk_provider_gender_s;




/************************

Standardized health economics

************************/

ALTER TABLE payer_plan_period DROP CONSTRAINT fpk_payer_plan_period;

ALTER TABLE cost DROP CONSTRAINT fpk_visit_cost_currency;

ALTER TABLE cost DROP CONSTRAINT fpk_visit_cost_period;

ALTER TABLE cost DROP CONSTRAINT fpk_drg_concept;

/************************

Standardized derived elements

************************/


--ALTER TABLE cohort DROP CONSTRAINT fpk_cohort_definition FOREIGN KEY (cohort_definition_id)  REFERENCES cohort_definition (cohort_definition_id);


ALTER TABLE cohort_attribute DROP CONSTRAINT fpk_ca_cohort_definition;

ALTER TABLE cohort_attribute DROP CONSTRAINT fpk_ca_attribute_definition;

ALTER TABLE cohort_attribute DROP CONSTRAINT fpk_ca_value;


ALTER TABLE drug_era DROP CONSTRAINT fpk_drug_era_person;

ALTER TABLE drug_era DROP CONSTRAINT fpk_drug_era_concept;


ALTER TABLE dose_era DROP CONSTRAINT fpk_dose_era_person;

ALTER TABLE dose_era DROP CONSTRAINT fpk_dose_era_concept;

ALTER TABLE dose_era DROP CONSTRAINT fpk_dose_era_unit_concept;


ALTER TABLE condition_era DROP CONSTRAINT fpk_condition_era_person;

ALTER TABLE condition_era DROP CONSTRAINT fpk_condition_era_concept;


/************************
*************************
*************************
*************************

Unique constraints

*************************
*************************
*************************
************************/

ALTER TABLE concept_synonym DROP CONSTRAINT uq_concept_synonym;
