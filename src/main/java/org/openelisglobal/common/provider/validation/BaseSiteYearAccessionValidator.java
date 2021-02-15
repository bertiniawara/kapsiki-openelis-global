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
package org.openelisglobal.common.provider.validation;

import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.Set;

import org.openelisglobal.common.provider.validation.IAccessionNumberValidator.ValidationResults;
import org.openelisglobal.common.util.ConfigurationProperties;
import org.openelisglobal.common.util.ConfigurationProperties.Property;
import org.openelisglobal.common.util.DateUtil;
import org.openelisglobal.internationalization.MessageUtil;
import org.openelisglobal.sample.service.SampleService;
import org.openelisglobal.spring.util.SpringContext;

public abstract class BaseSiteYearAccessionValidator {

    protected SampleService sampleService = SpringContext.getBean(SampleService.class);

    protected static final String INCREMENT_STARTING_VALUE = "0000000000001";
    protected static final long UPPER_INC_RANGE = 9999999999999L;
    protected static final int SITE_START = 0;
    protected int SITE_END = getSiteEndIndex();
    protected int YEAR_START = getYearStartIndex();
    protected int YEAR_END = getYearEndIndex();
    protected int INCREMENT_START = getIncrementStartIndex();
    protected int INCREMENT_END = getMaxAccessionLength();
    protected int MAX_LENGTH = getMaxAccessionLength();
    protected int MIN_LENGTH = getMinAccessionLength();
    protected static final boolean NEED_PROGRAM_CODE = false;

    public boolean needProgramCode() {
        return NEED_PROGRAM_CODE;
    }

    // input parameter is not used in this case
    public String createFirstAccessionNumber(String nullPrefix) {
        return getPrefix() + DateUtil.getTwoDigitYear() + INCREMENT_STARTING_VALUE;
    }

    public String getInvalidMessage(ValidationResults results) {
        String suggestedAccessionNumber = getNextAvailableAccessionNumber(null, true);

        return MessageUtil.getMessage("sample.entry.invalid.accession.number.suggestion") + " "
                + suggestedAccessionNumber;

    }

    // input parameter is not used in this case
    public String getNextAvailableAccessionNumber(String nullPrefix, boolean reserve) {

        String nextAccessionNumber;

        String curLargestAccessionNumber = sampleService.getLargestAccessionNumberMatchingPattern(getPrefix(),
                getMaxAccessionLength());

        Set<String> reservedNumbers = getReservedNumbers();
        if (curLargestAccessionNumber == null) {
            if (reservedNumbers.isEmpty()) {
                nextAccessionNumber = createFirstAccessionNumber(null);
            } else {
                nextAccessionNumber = reservedNumbers.iterator().next();
            }
        } else {
            nextAccessionNumber = incrementAccessionNumber(curLargestAccessionNumber);
        }

        while (reservedNumbers.contains(nextAccessionNumber)) {
            nextAccessionNumber = incrementAccessionNumber(nextAccessionNumber);
        }

        reservedNumbers.add(nextAccessionNumber);

        return nextAccessionNumber;
    }

    public String incrementAccessionNumber(String currentHighAccessionNumber) throws IllegalArgumentException {
        // if the year differs then start the sequence again. If not then
        // increment but check for overflow into year
        int year = new GregorianCalendar().get(Calendar.YEAR) - 2000;

        try {
            if (year != Integer.parseInt(currentHighAccessionNumber.substring(YEAR_START, YEAR_END))) {
                return createFirstAccessionNumber(null);
            }
        } catch (NumberFormatException e) {
            return createFirstAccessionNumber(null);
        }

        Long increment = Long.parseLong(currentHighAccessionNumber.substring(INCREMENT_START));
        String incrementAsString;

        if (increment < UPPER_INC_RANGE) {
            increment++;
            incrementAsString = String.format("%013d", increment);
        } else {
            throw new IllegalArgumentException("AccessionNumber has no next value");
        }

        return currentHighAccessionNumber.substring(SITE_START, YEAR_END) + incrementAsString;
    }

    // recordType parameter is not used in this case
    public boolean accessionNumberIsUsed(String accessionNumber, String recordType) {

        return sampleService.getSampleByAccessionNumber(accessionNumber) != null;
    }

    public ValidationResults checkAccessionNumberValidity(String accessionNumber, String recordType, String isRequired,
            String projectFormName) {

        ValidationResults results;
        boolean validateAccessionNumber = ConfigurationProperties.getInstance()
                .isPropertyValueEqual(Property.ACCESSION_NUMBER_VALIDATE, "true");
        if (validateAccessionNumber) {
            results = validFormat(accessionNumber, true);
        } else {
            results = ValidationResults.SUCCESS;

        }
        // TODO refactor accessionNumberIsUsed into two methods so the null isn't
        // needed. (Its only used for program accession number)
        if (results == ValidationResults.SUCCESS && accessionNumberIsUsed(accessionNumber, null)) {
            results = ValidationResults.USED_FAIL;
        }

        return results;
    }

    public ValidationResults validFormat(String accessionNumber, boolean checkDate) {
        if (accessionNumber.length() > MAX_LENGTH) {
            return ValidationResults.LENGTH_FAIL;
        }
        if (accessionNumber.length() < MIN_LENGTH) {
            return ValidationResults.LENGTH_FAIL;
        }

        if (!accessionNumber.substring(SITE_START, SITE_END).equals(getPrefix())) {
            return ValidationResults.SITE_FAIL;
        }

        if (checkDate) {
            int year = new GregorianCalendar().get(Calendar.YEAR);
            try {
                if ((year - 2000) != Integer.parseInt(accessionNumber.substring(YEAR_START, YEAR_END))) {
                    return ValidationResults.YEAR_FAIL;
                }
            } catch (NumberFormatException e) {
                return ValidationResults.YEAR_FAIL;
            }
        } else {
            try { // quick and dirty to make sure they are digits
                Integer.parseInt(accessionNumber.substring(YEAR_START, YEAR_END));
            } catch (NumberFormatException e) {
                return ValidationResults.YEAR_FAIL;
            }
        }

        try {
            Long.parseLong(accessionNumber.substring(INCREMENT_START));
        } catch (NumberFormatException e) {
            return ValidationResults.FORMAT_FAIL;
        }

        return ValidationResults.SUCCESS;
    }

    public String getInvalidFormatMessage(ValidationResults results) {
        return MessageUtil.getMessage("sample.entry.invalid.accession.number.format.corrected",
                new String[] { getFormatPattern(), getFormatExample() });
    }

    private String getFormatPattern() {
        StringBuilder format = new StringBuilder(getPrefix());
        format.append(MessageUtil.getMessage("date.two.digit.year"));
        for (int i = 0; i < getChangeableLength(); i++) {
            format.append("#");
        }
        return format.toString();
    }

    private String getFormatExample() {
        StringBuilder format = new StringBuilder(getPrefix());
        format.append(DateUtil.getTwoDigitYear());
        for (int i = 0; i < getChangeableLength() - 1; i++) {
            format.append("0");
        }

        format.append("1");

        return format.toString();
    }

    protected abstract Set<String> getReservedNumbers();

    protected abstract String getPrefix();

    protected abstract int getIncrementStartIndex();

    protected abstract int getYearEndIndex();

    protected abstract int getYearStartIndex();

    protected abstract int getSiteEndIndex();

    protected abstract int getMaxAccessionLength();

    protected abstract int getMinAccessionLength();

    protected abstract int getChangeableLength();

    protected abstract String getOverrideStartingAt();
}
