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



-- ALTER TABLE concept DROP CONSTRAINT xpk_concept PRIMARY KEY (concept_id);
--
-- ALTER TABLE vocabulary DROP CONSTRAINT xpk_vocabulary PRIMARY KEY (vocabulary_id);
--
-- ALTER TABLE domain DROP CONSTRAINT xpk_domain PRIMARY KEY (domain_id);
--
-- ALTER TABLE concept_class DROP CONSTRAINT xpk_concept_class PRIMARY KEY (concept_class_id);
--
-- ALTER TABLE concept_relationship DROP CONSTRAINT xpk_concept_relationship PRIMARY KEY (concept_id_1,concept_id_2,relationship_id);
--
-- ALTER TABLE relationship DROP CONSTRAINT xpk_relationship PRIMARY KEY (relationship_id);
--
-- ALTER TABLE concept_ancestor DROP CONSTRAINT xpk_concept_ancestor PRIMARY KEY (ancestor_concept_id,descendant_concept_id);
--
-- ALTER TABLE source_to_concept_map DROP CONSTRAINT xpk_source_to_concept_map PRIMARY KEY (source_vocabulary_id,target_concept_id,source_code,valid_end_date);
--
-- ALTER TABLE drug_strength DROP CONSTRAINT xpk_drug_strength PRIMARY KEY (drug_concept_id, ingredient_concept_id);
--
-- ALTER TABLE cohort_definition DROP CONSTRAINT xpk_cohort_definition PRIMARY KEY (cohort_definition_id);
--
-- ALTER TABLE attribute_definition DROP CONSTRAINT xpk_attribute_definition PRIMARY KEY (attribute_definition_id);


/**************************

Standardized meta-data

***************************/



/************************

Standardized clinical data

************************/


/**PRIMARY KEY NONCLUSTERED constraints**/

ALTER TABLE person DROP CONSTRAINT xpk_person;

ALTER TABLE observation_period DROP CONSTRAINT xpk_observation_period;

ALTER TABLE specimen DROP CONSTRAINT xpk_specimen;

ALTER TABLE death DROP CONSTRAINT xpk_death;

ALTER TABLE visit_occurrence DROP CONSTRAINT xpk_visit_occurrence;

ALTER TABLE visit_detail DROP CONSTRAINT xpk_visit_detail;

ALTER TABLE procedure_occurrence DROP CONSTRAINT xpk_procedure_occurrence;

ALTER TABLE drug_exposure DROP CONSTRAINT xpk_drug_exposure;

ALTER TABLE device_exposure DROP CONSTRAINT xpk_device_exposure;

ALTER TABLE condition_occurrence DROP CONSTRAINT xpk_condition_occurrence;

ALTER TABLE measurement DROP CONSTRAINT xpk_measurement;

ALTER TABLE note DROP CONSTRAINT xpk_note;

ALTER TABLE note_nlp DROP CONSTRAINT xpk_note_nlp;

ALTER TABLE observation  DROP CONSTRAINT xpk_observation;




/************************

Standardized health system data

************************/


ALTER TABLE location DROP CONSTRAINT xpk_location;

ALTER TABLE care_site DROP CONSTRAINT xpk_care_site;

ALTER TABLE provider DROP CONSTRAINT xpk_provider;



/************************

Standardized health economics

************************/


ALTER TABLE payer_plan_period DROP CONSTRAINT xpk_payer_plan_period;

ALTER TABLE cost DROP CONSTRAINT xpk_visit_cost;


/************************

Standardized derived elements

************************/

ALTER TABLE cohort DROP CONSTRAINT xpk_cohort;

ALTER TABLE cohort_attribute DROP CONSTRAINT xpk_cohort_attribute;

ALTER TABLE drug_era DROP CONSTRAINT xpk_drug_era;

ALTER TABLE dose_era  DROP CONSTRAINT xpk_dose_era;

ALTER TABLE condition_era DROP CONSTRAINT xpk_condition_era;


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

-- DROP INDEX idx_concept_concept_id  ON concept  (concept_id ASC);
-- CLUSTER concept  USING idx_concept_concept_id ;
-- DROP INDEX idx_concept_code ON concept (concept_code ASC);
-- DROP INDEX idx_concept_vocabluary_id ON concept (vocabulary_id ASC);
-- DROP INDEX idx_concept_domain_id ON concept (domain_id ASC);
-- DROP INDEX idx_concept_class_id ON concept (concept_class_id ASC);
--
-- DROP INDEX idx_vocabulary_vocabulary_id  ON vocabulary  (vocabulary_id ASC);
-- CLUSTER vocabulary  USING idx_vocabulary_vocabulary_id ;
--
-- DROP INDEX idx_domain_domain_id  ON domain  (domain_id ASC);
-- CLUSTER domain  USING idx_domain_domain_id ;
--
-- DROP INDEX idx_concept_class_class_id  ON concept_class  (concept_class_id ASC);
-- CLUSTER concept_class  USING idx_concept_class_class_id ;
--
-- DROP INDEX idx_concept_relationship_id_1 ON concept_relationship (concept_id_1 ASC);
-- DROP INDEX idx_concept_relationship_id_2 ON concept_relationship (concept_id_2 ASC);
-- DROP INDEX idx_concept_relationship_id_3 ON concept_relationship (relationship_id ASC);
--
-- DROP INDEX idx_relationship_rel_id  ON relationship  (relationship_id ASC);
-- CLUSTER relationship  USING idx_relationship_rel_id ;
--
-- DROP INDEX idx_concept_synonym_id  ON concept_synonym  (concept_id ASC);
-- CLUSTER concept_synonym  USING idx_concept_synonym_id ;
--
-- DROP INDEX idx_concept_ancestor_id_1  ON concept_ancestor  (ancestor_concept_id ASC);
-- CLUSTER concept_ancestor  USING idx_concept_ancestor_id_1 ;
-- DROP INDEX idx_concept_ancestor_id_2 ON concept_ancestor (descendant_concept_id ASC);
--
-- DROP INDEX idx_source_to_concept_map_id_3  ON source_to_concept_map  (target_concept_id ASC);
-- CLUSTER source_to_concept_map  USING idx_source_to_concept_map_id_3 ;
-- DROP INDEX idx_source_to_concept_map_id_1 ON source_to_concept_map (source_vocabulary_id ASC);
-- DROP INDEX idx_source_to_concept_map_id_2 ON source_to_concept_map (target_vocabulary_id ASC);
-- DROP INDEX idx_source_to_concept_map_code ON source_to_concept_map (source_code ASC);
--
-- DROP INDEX idx_drug_strength_id_1  ON drug_strength  (drug_concept_id ASC);
-- CLUSTER drug_strength  USING idx_drug_strength_id_1 ;
-- DROP INDEX idx_drug_strength_id_2 ON drug_strength (ingredient_concept_id ASC);
--
-- DROP INDEX idx_cohort_definition_id  ON cohort_definition  (cohort_definition_id ASC);
-- CLUSTER cohort_definition  USING idx_cohort_definition_id ;
--
-- DROP INDEX idx_attribute_definition_id  ON attribute_definition  (attribute_definition_id ASC);
-- CLUSTER attribute_definition  USING idx_attribute_definition_id ;


/**************************

Standardized meta-data

***************************/





/************************

Standardized clinical data

************************/

DROP INDEX idx_person_id;
--CLUSTER person  USING idx_person_id ;

DROP INDEX idx_observation_period_id;
--CLUSTER observation_period  USING idx_observation_period_id ;

DROP INDEX idx_specimen_person_id;
--CLUSTER specimen  USING idx_specimen_person_id ;
DROP INDEX idx_specimen_concept_id;

DROP INDEX idx_death_person_id;
--CLUSTER death  USING idx_death_person_id ;

DROP INDEX idx_visit_person_id;
--CLUSTER visit_occurrence  USING idx_visit_person_id ;
DROP INDEX idx_visit_concept_id;

DROP INDEX idx_visit_detail_person_id;
--CLUSTER visit_detail  USING idx_visit_detail_person_id ;
DROP INDEX idx_visit_detail_concept_id;

DROP INDEX idx_procedure_person_id;
--CLUSTER procedure_occurrence  USING idx_procedure_person_id ;
DROP INDEX idx_procedure_concept_id;
DROP INDEX idx_procedure_visit_id;

DROP INDEX idx_drug_person_id;
--CLUSTER drug_exposure  USING idx_drug_person_id ;
DROP INDEX idx_drug_concept_id;
DROP INDEX idx_drug_visit_id;

DROP INDEX idx_device_person_id;
--CLUSTER device_exposure  USING idx_device_person_id ;
DROP INDEX idx_device_concept_id;
DROP INDEX idx_device_visit_id;

DROP INDEX idx_condition_person_id;
--CLUSTER condition_occurrence  USING idx_condition_person_id ;
DROP INDEX idx_condition_concept_id;
DROP INDEX idx_condition_visit_id;

DROP INDEX idx_measurement_person_id;
--CLUSTER measurement  USING idx_measurement_person_id ;
DROP INDEX idx_measurement_concept_id;
DROP INDEX idx_measurement_visit_id;

DROP INDEX idx_note_person_id;
--CLUSTER note  USING idx_note_person_id ;
DROP INDEX idx_note_concept_id;
DROP INDEX idx_note_visit_id;

DROP INDEX idx_note_nlp_note_id;
--CLUSTER note_nlp  USING idx_note_nlp_note_id ;
DROP INDEX idx_note_nlp_concept_id;

DROP INDEX idx_observation_person_id;
--CLUSTER observation  USING idx_observation_person_id ;
DROP INDEX idx_observation_concept_id;
DROP INDEX idx_observation_visit_id;

DROP INDEX idx_fact_relationship_id_1;
DROP INDEX idx_fact_relationship_id_2;
DROP INDEX idx_fact_relationship_id_3;



/************************

Standardized health system data

************************/





/************************

Standardized health economics

************************/

DROP INDEX idx_period_person_id;
--CLUSTER payer_plan_period  USING idx_period_person_id ;





/************************

Standardized derived elements

************************/


DROP INDEX idx_cohort_subject_id;
DROP INDEX idx_cohort_c_definition_id;

DROP INDEX idx_ca_subject_id;
DROP INDEX idx_ca_definition_id;

DROP INDEX idx_drug_era_person_id;
--CLUSTER drug_era  USING idx_drug_era_person_id ;
DROP INDEX idx_drug_era_concept_id;

DROP INDEX idx_dose_era_person_id;
--CLUSTER dose_era  USING idx_dose_era_person_id ;
DROP INDEX idx_dose_era_concept_id;

DROP INDEX idx_condition_era_person_id;
--CLUSTER condition_era  USING idx_condition_era_person_id ;
DROP INDEX idx_condition_era_concept_id;