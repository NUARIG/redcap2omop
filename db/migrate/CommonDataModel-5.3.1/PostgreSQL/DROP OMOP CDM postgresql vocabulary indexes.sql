/*********************************************************************************
# Copyright 2014 Observational Health Data Sciences and Informatics
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
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

 ####### #     # ####### ######      #####  ######  #     #           #######      #####     ###
 #     # ##   ## #     # #     #    #     # #     # ##   ##    #    # #           #     #     #  #    # #####  ###### #    # ######  ####
 #     # # # # # #     # #     #    #       #     # # # # #    #    # #                 #     #  ##   # #    # #       #  #  #      #
 #     # #  #  # #     # ######     #       #     # #  #  #    #    # ######       #####      #  # #  # #    # #####    ##   #####   ####
 #     # #     # #     # #          #       #     # #     #    #    #       # ###       #     #  #  # # #    # #        ##   #           #
 #     # #     # #     # #          #     # #     # #     #     #  #  #     # ### #     #     #  #   ## #    # #       #  #  #      #    #
 ####### #     # ####### #           #####  ######  #     #      ##    #####  ###  #####     ### #    # #####  ###### #    # ######  ####


postgresql script to create the required indexes within OMOP common data model, version 5.3

last revised: 14-November-2017

author:  Patrick Ryan, Clair Blacketer

description:  These primary keys and indices are considered a minimal requirement to ensure adequate performance of analyses.

*************************/


/************************
*************************
*************************
*************************

Primary key constraints

*************************
*************************
*************************
************************/



/************************

Standardized vocabulary

************************/



ALTER TABLE concept DROP CONSTRAINT xpk_concept;

ALTER TABLE vocabulary DROP CONSTRAINT xpk_vocabulary;

ALTER TABLE domain DROP CONSTRAINT xpk_domain;

ALTER TABLE concept_class DROP CONSTRAINT xpk_concept_class;

ALTER TABLE concept_relationship DROP CONSTRAINT xpk_concept_relationship;

ALTER TABLE relationship DROP CONSTRAINT xpk_relationship;

ALTER TABLE concept_ancestor DROP CONSTRAINT xpk_concept_ancestor;

ALTER TABLE source_to_concept_map DROP CONSTRAINT xpk_source_to_concept_map;

ALTER TABLE drug_strength DROP CONSTRAINT xpk_drug_strength;

ALTER TABLE cohort_definition DROP CONSTRAINT xpk_cohort_definition;

ALTER TABLE attribute_definition DROP CONSTRAINT xpk_attribute_definition;

/**************************

Standardized meta-data

***************************/



/************************

Standardized clinical data

************************/


/**PRIMARY KEY NONCLUSTERED constraints**/

-- ALTER TABLE person DROP CONSTRAINT xpk_person PRIMARY KEY ( person_id ) ;
--
-- ALTER TABLE observation_period DROP CONSTRAINT xpk_observation_period PRIMARY KEY ( observation_period_id ) ;
--
-- ALTER TABLE specimen DROP CONSTRAINT xpk_specimen PRIMARY KEY ( specimen_id ) ;
--
-- ALTER TABLE death DROP CONSTRAINT xpk_death PRIMARY KEY ( person_id ) ;
--
-- ALTER TABLE visit_occurrence DROP CONSTRAINT xpk_visit_occurrence PRIMARY KEY ( visit_occurrence_id ) ;
--
-- ALTER TABLE visit_detail DROP CONSTRAINT xpk_visit_detail PRIMARY KEY ( visit_detail_id ) ;
--
-- ALTER TABLE procedure_occurrence DROP CONSTRAINT xpk_procedure_occurrence PRIMARY KEY ( procedure_occurrence_id ) ;
--
-- ALTER TABLE drug_exposure DROP CONSTRAINT xpk_drug_exposure PRIMARY KEY ( drug_exposure_id ) ;
--
-- ALTER TABLE device_exposure DROP CONSTRAINT xpk_device_exposure PRIMARY KEY ( device_exposure_id ) ;
--
-- ALTER TABLE condition_occurrence DROP CONSTRAINT xpk_condition_occurrence PRIMARY KEY ( condition_occurrence_id ) ;
--
-- ALTER TABLE measurement DROP CONSTRAINT xpk_measurement PRIMARY KEY ( measurement_id ) ;
--
-- ALTER TABLE note DROP CONSTRAINT xpk_note PRIMARY KEY ( note_id ) ;
--
-- ALTER TABLE note_nlp DROP CONSTRAINT xpk_note_nlp PRIMARY KEY ( note_nlp_id ) ;
--
-- ALTER TABLE observation  DROP CONSTRAINT xpk_observation PRIMARY KEY ( observation_id ) ;




/************************

Standardized health system data

************************/


-- ALTER TABLE location DROP CONSTRAINT xpk_location PRIMARY KEY ( location_id ) ;
--
-- ALTER TABLE care_site DROP CONSTRAINT xpk_care_site PRIMARY KEY ( care_site_id ) ;
--
-- ALTER TABLE provider DROP CONSTRAINT xpk_provider PRIMARY KEY ( provider_id ) ;



/************************

Standardized health economics

************************/


-- ALTER TABLE payer_plan_period DROP CONSTRAINT xpk_payer_plan_period PRIMARY KEY ( payer_plan_period_id ) ;
--
-- ALTER TABLE cost DROP CONSTRAINT xpk_visit_cost PRIMARY KEY ( cost_id ) ;


/************************

Standardized derived elements

************************/

-- ALTER TABLE cohort DROP CONSTRAINT xpk_cohort PRIMARY KEY ( cohort_definition_id, subject_id, cohort_start_date, cohort_end_date  ) ;
--
-- ALTER TABLE cohort_attribute DROP CONSTRAINT xpk_cohort_attribute PRIMARY KEY ( cohort_definition_id, subject_id, cohort_start_date, cohort_end_date, attribute_definition_id ) ;
--
-- ALTER TABLE drug_era DROP CONSTRAINT xpk_drug_era PRIMARY KEY ( drug_era_id ) ;
--
-- ALTER TABLE dose_era  DROP CONSTRAINT xpk_dose_era PRIMARY KEY ( dose_era_id ) ;
--
-- ALTER TABLE condition_era DROP CONSTRAINT xpk_condition_era PRIMARY KEY ( condition_era_id ) ;


/************************
*************************
*************************
*************************

Indices

*************************
*************************
*************************
************************/

/************************

Standardized vocabulary

************************/

DROP INDEX idx_concept_concept_id;
--CLUSTER concept  USING idx_concept_concept_id ;
DROP INDEX idx_concept_code;
DROP INDEX idx_concept_vocabluary_id;
DROP INDEX idx_concept_domain_id;
DROP INDEX idx_concept_class_id;

DROP INDEX idx_vocabulary_vocabulary_id;
--CLUSTER vocabulary  USING idx_vocabulary_vocabulary_id ;

DROP INDEX idx_domain_domain_id;
--CLUSTER domain  USING idx_domain_domain_id ;

DROP INDEX idx_concept_class_class_id;
--CLUSTER concept_class  USING idx_concept_class_class_id ;

DROP INDEX idx_concept_relationship_id_1;
DROP INDEX idx_concept_relationship_id_2;
DROP INDEX idx_concept_relationship_id_3;

DROP INDEX idx_relationship_rel_id;
--CLUSTER relationship  USING idx_relationship_rel_id ;

DROP INDEX idx_concept_synonym_id;
--CLUSTER concept_synonym  USING idx_concept_synonym_id ;

DROP INDEX idx_concept_ancestor_id_1;
--CLUSTER concept_ancestor  USING idx_concept_ancestor_id_1 ;
DROP INDEX idx_concept_ancestor_id_2;

DROP INDEX idx_source_to_concept_map_id_3;
--CLUSTER source_to_concept_map  USING idx_source_to_concept_map_id_3 ;
DROP INDEX idx_source_to_concept_map_id_1;
DROP INDEX idx_source_to_concept_map_id_2;
DROP INDEX idx_source_to_concept_map_code;

DROP INDEX idx_drug_strength_id_1;
--CLUSTER drug_strength  USING idx_drug_strength_id_1 ;
DROP INDEX idx_drug_strength_id_2;

DROP INDEX idx_cohort_definition_id;
--CLUSTER cohort_definition  USING idx_cohort_definition_id ;

DROP INDEX idx_attribute_definition_id;
--CLUSTER attribute_definition  USING idx_attribute_definition_id ;


/**************************

Standardized meta-data

***************************/





/************************

Standardized clinical data

************************/

-- DROP INDEX idx_person_id  ON person  (person_id ASC);
-- CLUSTER person  USING idx_person_id ;
--
-- DROP INDEX idx_observation_period_id  ON observation_period  (person_id ASC);
-- CLUSTER observation_period  USING idx_observation_period_id ;
--
-- DROP INDEX idx_specimen_person_id  ON specimen  (person_id ASC);
-- CLUSTER specimen  USING idx_specimen_person_id ;
-- DROP INDEX idx_specimen_concept_id ON specimen (specimen_concept_id ASC);
--
-- DROP INDEX idx_death_person_id  ON death  (person_id ASC);
-- CLUSTER death  USING idx_death_person_id ;
--
-- DROP INDEX idx_visit_person_id  ON visit_occurrence  (person_id ASC);
-- CLUSTER visit_occurrence  USING idx_visit_person_id ;
-- DROP INDEX idx_visit_concept_id ON visit_occurrence (visit_concept_id ASC);
--
-- DROP INDEX idx_visit_detail_person_id  ON visit_detail  (person_id ASC);
-- CLUSTER visit_detail  USING idx_visit_detail_person_id ;
-- DROP INDEX idx_visit_detail_concept_id ON visit_detail (visit_detail_concept_id ASC);
--
-- DROP INDEX idx_procedure_person_id  ON procedure_occurrence  (person_id ASC);
-- CLUSTER procedure_occurrence  USING idx_procedure_person_id ;
-- DROP INDEX idx_procedure_concept_id ON procedure_occurrence (procedure_concept_id ASC);
-- DROP INDEX idx_procedure_visit_id ON procedure_occurrence (visit_occurrence_id ASC);
--
-- DROP INDEX idx_drug_person_id  ON drug_exposure  (person_id ASC);
-- CLUSTER drug_exposure  USING idx_drug_person_id ;
-- DROP INDEX idx_drug_concept_id ON drug_exposure (drug_concept_id ASC);
-- DROP INDEX idx_drug_visit_id ON drug_exposure (visit_occurrence_id ASC);
--
-- DROP INDEX idx_device_person_id  ON device_exposure  (person_id ASC);
-- CLUSTER device_exposure  USING idx_device_person_id ;
-- DROP INDEX idx_device_concept_id ON device_exposure (device_concept_id ASC);
-- DROP INDEX idx_device_visit_id ON device_exposure (visit_occurrence_id ASC);
--
-- DROP INDEX idx_condition_person_id  ON condition_occurrence  (person_id ASC);
-- CLUSTER condition_occurrence  USING idx_condition_person_id ;
-- DROP INDEX idx_condition_concept_id ON condition_occurrence (condition_concept_id ASC);
-- DROP INDEX idx_condition_visit_id ON condition_occurrence (visit_occurrence_id ASC);
--
-- DROP INDEX idx_measurement_person_id  ON measurement  (person_id ASC);
-- CLUSTER measurement  USING idx_measurement_person_id ;
-- DROP INDEX idx_measurement_concept_id ON measurement (measurement_concept_id ASC);
-- DROP INDEX idx_measurement_visit_id ON measurement (visit_occurrence_id ASC);
--
-- DROP INDEX idx_note_person_id  ON note  (person_id ASC);
-- CLUSTER note  USING idx_note_person_id ;
-- DROP INDEX idx_note_concept_id ON note (note_type_concept_id ASC);
-- DROP INDEX idx_note_visit_id ON note (visit_occurrence_id ASC);
--
-- DROP INDEX idx_note_nlp_note_id  ON note_nlp  (note_id ASC);
-- CLUSTER note_nlp  USING idx_note_nlp_note_id ;
-- DROP INDEX idx_note_nlp_concept_id ON note_nlp (note_nlp_concept_id ASC);
--
-- DROP INDEX idx_observation_person_id  ON observation  (person_id ASC);
-- CLUSTER observation  USING idx_observation_person_id ;
-- DROP INDEX idx_observation_concept_id ON observation (observation_concept_id ASC);
-- DROP INDEX idx_observation_visit_id ON observation (visit_occurrence_id ASC);
--
-- DROP INDEX idx_fact_relationship_id_1 ON fact_relationship (domain_concept_id_1 ASC);
-- DROP INDEX idx_fact_relationship_id_2 ON fact_relationship (domain_concept_id_2 ASC);
-- DROP INDEX idx_fact_relationship_id_3 ON fact_relationship (relationship_concept_id ASC);



/************************

Standardized health system data

************************/





/************************

Standardized health economics

************************/

-- DROP INDEX idx_period_person_id  ON payer_plan_period  (person_id ASC);
-- CLUSTER payer_plan_period  USING idx_period_person_id ;





/************************

Standardized derived elements

************************/


-- DROP INDEX idx_cohort_subject_id ON cohort (subject_id ASC);
-- DROP INDEX idx_cohort_c_definition_id ON cohort (cohort_definition_id ASC);
--
-- DROP INDEX idx_ca_subject_id ON cohort_attribute (subject_id ASC);
-- DROP INDEX idx_ca_definition_id ON cohort_attribute (cohort_definition_id ASC);
--
-- DROP INDEX idx_drug_era_person_id  ON drug_era  (person_id ASC);
-- CLUSTER drug_era  USING idx_drug_era_person_id ;
-- DROP INDEX idx_drug_era_concept_id ON drug_era (drug_concept_id ASC);
--
-- DROP INDEX idx_dose_era_person_id  ON dose_era  (person_id ASC);
-- CLUSTER dose_era  USING idx_dose_era_person_id ;
-- DROP INDEX idx_dose_era_concept_id ON dose_era (drug_concept_id ASC);
--
-- DROP INDEX idx_condition_era_person_id  ON condition_era  (person_id ASC);
-- CLUSTER condition_era  USING idx_condition_era_person_id ;
-- DROP INDEX idx_condition_era_concept_id ON condition_era (condition_concept_id ASC);