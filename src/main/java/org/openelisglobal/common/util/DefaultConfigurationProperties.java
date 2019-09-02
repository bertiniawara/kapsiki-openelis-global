/**
* The contents of this file are subject to the Mozilla Public License
* Version 1.1 (the "License"); you may not use this file except in
* compliance with the License. You may obtain a copy of the License at
* http://www.mozilla.org/MPL/
*
* Software distributed under the License is distributed on an "AS IS"
* basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
* License for the specific language governing rights and limitations under
* the License.
*
* The Original Code is OpenELIS code.
*
* Copyright (C) CIRG, University of Washington, Seattle WA.  All Rights Reserved.
*
*/
package org.openelisglobal.common.util;

import java.io.InputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.openelisglobal.common.action.IActionConstants;
import org.openelisglobal.common.log.LogEvent;
import org.openelisglobal.siteinformation.service.SiteInformationService;
import org.openelisglobal.siteinformation.valueholder.SiteInformation;
import org.openelisglobal.spring.util.SpringContext;

public class DefaultConfigurationProperties extends ConfigurationProperties {

    private static String propertyFile = "/SystemConfiguration.properties";
    private java.util.Properties properties = null;
    protected static Map<ConfigurationProperties.Property, KeyDefaultPair> propertiesFileMap;
    protected static Map<String, ConfigurationProperties.Property> dbNamePropertiesMap;
    private boolean databaseLoaded = false;

    {
        // config from SystemConfiguration.properties
        propertiesFileMap = new HashMap<>();
        propertiesFileMap.put(Property.AmbiguousDateValue, new KeyDefaultPair("date.ambiguous.date.value", "01"));
        propertiesFileMap.put(Property.AmbiguousDateHolder, new KeyDefaultPair("date.ambiguous.date.holder", "X"));
        propertiesFileMap.put(Property.ReferingLabParentOrg,
                new KeyDefaultPair("organization.reference.lab.parent", null));
        propertiesFileMap.put(Property.resultsResendTime, new KeyDefaultPair("results.send.retry.time", "30"));
//		propertiesFileMap.put(Property. , new KeyDefaultPair() );

        // config from site_information table
        dbNamePropertiesMap = new HashMap<>();
        setDBPropertyMappingAndDefault(Property.SiteCode, Property.SiteCode.getName(), "");
        setDBPropertyMappingAndDefault(Property.TrainingInstallation, Property.TrainingInstallation.getName(), "false");
        setDBPropertyMappingAndDefault(Property.PatientSearchURL, Property.PatientSearchURL.getName(), "");
        setDBPropertyMappingAndDefault(Property.PatientSearchUserName, Property.PatientSearchUserName.getName(), "");
        setDBPropertyMappingAndDefault(Property.PatientSearchPassword, Property.PatientSearchPassword.getName(), "");
        setDBPropertyMappingAndDefault(Property.UseExternalPatientInfo, Property.UseExternalPatientInfo.getName(), "false");
        setDBPropertyMappingAndDefault(Property.labDirectorName, Property.labDirectorName.getName(), "");
        setDBPropertyMappingAndDefault(Property.languageSwitch, Property.languageSwitch.getName(), "true");
        setDBPropertyMappingAndDefault(Property.resultReportingURL, Property.resultReportingURL.getName(), "");
        setDBPropertyMappingAndDefault(Property.reportResults, Property.reportResults.getName(), "false");
        setDBPropertyMappingAndDefault(Property.malariaSurveillanceReportURL, Property.malariaSurveillanceReportURL.getName(), "");
        setDBPropertyMappingAndDefault(Property.malariaSurveillanceReport, Property.malariaSurveillanceReport.getName(), "false");
        setDBPropertyMappingAndDefault(Property.malariaCaseReport, Property.malariaCaseReport.getName(), "false");
        setDBPropertyMappingAndDefault(Property.malariaCaseReportURL, Property.malariaCaseReportURL.getName(), "");
        setDBPropertyMappingAndDefault(Property.testUsageReportingURL, Property.testUsageReportingURL.getName(), "");
        setDBPropertyMappingAndDefault(Property.testUsageReporting, Property.testUsageReporting.getName(), "false");
        setDBPropertyMappingAndDefault(Property.roleRequiredForModifyResults, Property.roleRequiredForModifyResults.getName(), "false");
        setDBPropertyMappingAndDefault(Property.notesRequiredForModifyResults, Property.notesRequiredForModifyResults.getName(), "false");
        setDBPropertyMappingAndDefault(Property.resultTechnicianName, Property.resultTechnicianName.getName(), "false");
        setDBPropertyMappingAndDefault(Property.allowResultRejection, Property.allowResultRejection.getName(), "false");
        setDBPropertyMappingAndDefault(Property.restrictFreeTextRefSiteEntry, Property.restrictFreeTextRefSiteEntry.getName(), "false");
        setDBPropertyMappingAndDefault(Property.autoFillTechNameBox, Property.autoFillTechNameBox.getName(), "false");
        setDBPropertyMappingAndDefault(Property.autoFillTechNameUser, Property.autoFillTechNameUser.getName(), "false");
        setDBPropertyMappingAndDefault(Property.failedValidationMarker, Property.failedValidationMarker.getName(), "true");
        setDBPropertyMappingAndDefault(Property.SiteName, Property.SiteName.getName(), "");
        setDBPropertyMappingAndDefault(Property.PasswordRequirments, Property.PasswordRequirments.getName(), "MINN");
        setDBPropertyMappingAndDefault(Property.FormFieldSet, Property.FormFieldSet.getName(),
                IActionConstants.FORM_FIELD_SET_CI_GENERAL);
        setDBPropertyMappingAndDefault(Property.StringContext, Property.StringContext.getName(), "");
        setDBPropertyMappingAndDefault(Property.StatusRules, Property.StatusRules.getName(), "CI");
        setDBPropertyMappingAndDefault(Property.ReflexAction, Property.ReflexAction.getName(), "Haiti");
        setDBPropertyMappingAndDefault(Property.AccessionFormat, Property.AccessionFormat.getName(), "SITEYEARNUM"); // spelled wrong in
                                                                                                   // DB
        setDBPropertyMappingAndDefault(Property.TRACK_PATIENT_PAYMENT, Property.TRACK_PATIENT_PAYMENT.getName(), "false");
        setDBPropertyMappingAndDefault(Property.ALERT_FOR_INVALID_RESULTS, Property.ALERT_FOR_INVALID_RESULTS.getName(), "false");
        setDBPropertyMappingAndDefault(Property.DEFAULT_DATE_LOCALE, Property.DEFAULT_DATE_LOCALE.getName(), "fr-FR");
        setDBPropertyMappingAndDefault(Property.DEFAULT_LANG_LOCALE, Property.DEFAULT_LANG_LOCALE.getName(), "fr-FR");
        setDBPropertyMappingAndDefault(Property.configurationName, Property.configurationName.getName(), "not set");
        setDBPropertyMappingAndDefault(Property.CONDENSE_NFS_PANEL, Property.CONDENSE_NFS_PANEL.getName(), "false");
        setDBPropertyMappingAndDefault(Property.PATIENT_DATA_ON_RESULTS_BY_ROLE, Property.PATIENT_DATA_ON_RESULTS_BY_ROLE.getName(), "false");
        setDBPropertyMappingAndDefault(Property.USE_PAGE_NUMBERS_ON_REPORTS, Property.USE_PAGE_NUMBERS_ON_REPORTS.getName(), "true");
        setDBPropertyMappingAndDefault(Property.QA_SORT_EVENT_LIST, Property.QA_SORT_EVENT_LIST.getName(), "true");
        setDBPropertyMappingAndDefault(Property.ALWAYS_VALIDATE_RESULTS, Property.ALWAYS_VALIDATE_RESULTS.getName(), "true");
        setDBPropertyMappingAndDefault(Property.ADDITIONAL_SITE_INFO, Property.ADDITIONAL_SITE_INFO.getName(), "");
        setDBPropertyMappingAndDefault(Property.SUBJECT_ON_WORKPLAN, Property.SUBJECT_ON_WORKPLAN.getName(), "false");
        setDBPropertyMappingAndDefault(Property.NEXT_VISIT_DATE_ON_WORKPLAN, Property.NEXT_VISIT_DATE_ON_WORKPLAN.getName(), "false");
        setDBPropertyMappingAndDefault(Property.ACCEPT_EXTERNAL_ORDERS, Property.ACCEPT_EXTERNAL_ORDERS.getName(), "false");
        setDBPropertyMappingAndDefault(Property.SIGNATURES_ON_NONCONFORMITY_REPORTS, Property.SIGNATURES_ON_NONCONFORMITY_REPORTS.getName(),
                "false");
        setDBPropertyMappingAndDefault(Property.AUTOFILL_COLLECTION_DATE, Property.AUTOFILL_COLLECTION_DATE.getName(), "true");
        setDBPropertyMappingAndDefault(Property.RESULTS_ON_WORKPLAN, Property.RESULTS_ON_WORKPLAN.getName(), "false");
        setDBPropertyMappingAndDefault(Property.NONCONFORMITY_RECEPTION_AS_UNIT, Property.NONCONFORMITY_RECEPTION_AS_UNIT.getName(), "true");
        setDBPropertyMappingAndDefault(Property.NONCONFORMITY_SAMPLE_COLLECTION_AS_UNIT, Property.NONCONFORMITY_SAMPLE_COLLECTION_AS_UNIT.getName(), "false");
        setDBPropertyMappingAndDefault(Property.ACCESSION_NUMBER_PREFIX, Property.ACCESSION_NUMBER_PREFIX.getName(), "");
        setDBPropertyMappingAndDefault(Property.NOTE_EXTERNAL_ONLY_FOR_VALIDATION, Property.NOTE_EXTERNAL_ONLY_FOR_VALIDATION.getName(),
                "false");
        setDBPropertyMappingAndDefault(Property.PHONE_FORMAT, Property.PHONE_FORMAT.getName(), "(ddd) dddd-dddd");
        setDBPropertyMappingAndDefault(Property.VALIDATE_PHONE_FORMAT, Property.VALIDATE_PHONE_FORMAT.getName(), "true");
        setDBPropertyMappingAndDefault(Property.ALLOW_DUPLICATE_SUBJECT_NUMBERS, Property.ALLOW_DUPLICATE_SUBJECT_NUMBERS.getName(),
                "true");
        setDBPropertyMappingAndDefault(Property.VALIDATE_REJECTED_TESTS, Property.VALIDATE_REJECTED_TESTS.getName(), "false");
        setDBPropertyMappingAndDefault(Property.TEST_NAME_AUGMENTED, Property.TEST_NAME_AUGMENTED.getName(), "true");
        setDBPropertyMappingAndDefault(Property.USE_BILLING_REFERENCE_NUMBER, Property.USE_BILLING_REFERENCE_NUMBER.getName(), "false");
        setDBPropertyMappingAndDefault(Property.BILLING_REFERENCE_NUMBER_LABEL, Property.BILLING_REFERENCE_NUMBER_LABEL.getName(), "-1");
        setDBPropertyMappingAndDefault(Property.ORDER_PROGRAM, Property.ORDER_PROGRAM.getName(), "true");
        setDBPropertyMappingAndDefault(Property.BANNER_TEXT, Property.BANNER_TEXT.getName(), "-1");
        setDBPropertyMappingAndDefault(Property.CLOCK_24, Property.CLOCK_24.getName(), "true");
        setDBPropertyMappingAndDefault(Property.PATIENT_NATIONALITY, Property.PATIENT_NATIONALITY.getName(), "false");
        setDBPropertyMappingAndDefault(Property.PATIENT_ID_REQUIRED, Property.PATIENT_ID_REQUIRED.getName(), "true");
        setDBPropertyMappingAndDefault(Property.PATIENT_SUBJECT_NUMBER_REQUIRED, Property.PATIENT_SUBJECT_NUMBER_REQUIRED.getName(), "true");
        setDBPropertyMappingAndDefault(Property.QA_SAMPLE_ID_REQUIRED, Property.QA_SAMPLE_ID_REQUIRED.getName(), "false");
        setDBPropertyMappingAndDefault(Property.MAX_ORDER_PRINTED, Property.MAX_ORDER_PRINTED.getName(), "10");
        setDBPropertyMappingAndDefault(Property.MAX_SPECIMEN_PRINTED, Property.MAX_SPECIMEN_PRINTED.getName(), "1");
        setDBPropertyMappingAndDefault(Property.MAX_ALIQUOT_PRINTED, Property.MAX_ALIQUOT_PRINTED.getName(), "1");
        setDBPropertyMappingAndDefault(Property.ORDER_BARCODE_HEIGHT, Property.ORDER_BARCODE_HEIGHT.getName(), "25.4");
        setDBPropertyMappingAndDefault(Property.ORDER_BARCODE_WIDTH, Property.ORDER_BARCODE_WIDTH.getName(), "76.2");
        setDBPropertyMappingAndDefault(Property.SPECIMEN_BARCODE_HEIGHT, Property.SPECIMEN_BARCODE_HEIGHT.getName(), "25.4");
        setDBPropertyMappingAndDefault(Property.SPECIMEN_BARCODE_WIDTH, Property.SPECIMEN_BARCODE_WIDTH.getName(), "76.2");
        setDBPropertyMappingAndDefault(Property.SPECIMEN_FIELD_DATE, Property.SPECIMEN_FIELD_DATE.getName(), "true");
        setDBPropertyMappingAndDefault(Property.SPECIMEN_FIELD_SEX, Property.SPECIMEN_FIELD_SEX.getName(), "true");
        setDBPropertyMappingAndDefault(Property.SPECIMEN_FIELD_TESTS, Property.SPECIMEN_FIELD_TESTS.getName(), "true");
    }

    private void setDBPropertyMappingAndDefault(Property property, String dbName, String defaultValue) {
        dbNamePropertiesMap.put(dbName, property);
        propertiesValueMap.put(property, defaultValue);
    }

    protected DefaultConfigurationProperties() {
        loadFromPropertiesFile();
        loadSpecial();
    }

    @Override
    protected void loadIfPropertyValueNeeded(Property property) {
        if (!databaseLoaded && dbNamePropertiesMap.containsValue(property)) {
            loadFromDatabase();
        }
    }

    protected void loadFromDatabase() {
        SiteInformationService siteInformationService = SpringContext.getBean(SiteInformationService.class);
        List<SiteInformation> siteInformationList = siteInformationService.getAllSiteInformation();

        for (SiteInformation siteInformation : siteInformationList) {
            Property property = dbNamePropertiesMap.get(siteInformation.getName());
            if (property != null) {
                propertiesValueMap.put(property, siteInformation.getValue());
            }
        }

        databaseLoaded = true;
    }

    protected void loadFromPropertiesFile() {
        InputStream propertyStream = null;

        try {
            propertyStream = this.getClass().getResourceAsStream(propertyFile);

            // Now load a java.util.Properties object with the properties
            properties = new java.util.Properties();

            properties.load(propertyStream);

        } catch (Exception e) {
            LogEvent.logError("DefaultConfigurationProperties", "", e.toString());
        } finally {
            if (null != propertyStream) {
                try {
                    propertyStream.close();
                    propertyStream = null;
                } catch (Exception e) {
                    LogEvent.logError("DefaultConfigurationProperties", "", e.toString());
                }
            }

        }

        for (Property property : propertiesFileMap.keySet()) {
            KeyDefaultPair pair = propertiesFileMap.get(property);
            String value = properties.getProperty(pair.key, pair.defaultValue);
            propertiesValueMap.put(property, value);
        }
    }

    private void loadSpecial() {
        propertiesValueMap.put(Property.releaseNumber, Versioning.getReleaseNumber());
        propertiesValueMap.put(Property.buildNumber, Versioning.getBuildNumber());
    }

    protected class KeyDefaultPair {
        public final String key;
        public final String defaultValue;

        public KeyDefaultPair(String key, String defaultValue) {
            this.key = key;
            this.defaultValue = defaultValue;
        }
    }
}
