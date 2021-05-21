package org.openelisglobal.referral.fhir.service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import javax.annotation.PostConstruct;
import javax.transaction.Transactional;

import org.apache.commons.lang3.StringUtils;
import org.hl7.fhir.r4.model.Bundle;
import org.hl7.fhir.r4.model.Bundle.BundleEntryComponent;
import org.hl7.fhir.r4.model.CodeableConcept;
import org.hl7.fhir.r4.model.Coding;
import org.hl7.fhir.r4.model.Observation;
import org.hl7.fhir.r4.model.Organization;
import org.hl7.fhir.r4.model.Patient;
import org.hl7.fhir.r4.model.Practitioner;
import org.hl7.fhir.r4.model.Quantity;
import org.hl7.fhir.r4.model.Reference;
import org.hl7.fhir.r4.model.Resource;
import org.hl7.fhir.r4.model.ServiceRequest;
import org.hl7.fhir.r4.model.StringType;
import org.hl7.fhir.r4.model.Task;
import org.hl7.fhir.r4.model.Task.TaskRestrictionComponent;
import org.hl7.fhir.r4.model.Task.TaskStatus;
import org.openelisglobal.analysis.service.AnalysisService;
import org.openelisglobal.analysis.valueholder.Analysis;
import org.openelisglobal.common.log.LogEvent;
import org.openelisglobal.common.services.IResultSaveService;
import org.openelisglobal.common.services.IStatusService;
import org.openelisglobal.common.services.StatusService.AnalysisStatus;
import org.openelisglobal.common.services.registration.ValidationUpdateRegister;
import org.openelisglobal.common.services.registration.interfaces.IResultUpdate;
import org.openelisglobal.common.util.DateUtil;
import org.openelisglobal.dataexchange.fhir.FhirConfig;
import org.openelisglobal.dataexchange.fhir.exception.FhirLocalPersistingException;
import org.openelisglobal.dataexchange.fhir.exception.FhirPersistanceException;
import org.openelisglobal.dataexchange.fhir.service.FhirApiWorkFlowServiceImpl.ReferralResultsImportObjects;
import org.openelisglobal.dataexchange.fhir.service.FhirPersistanceService;
import org.openelisglobal.dataexchange.fhir.service.FhirTransformService;
import org.openelisglobal.dataexchange.orderresult.OrderResponseWorker.Event;
import org.openelisglobal.dictionary.service.DictionaryService;
import org.openelisglobal.note.service.NoteService;
import org.openelisglobal.note.service.NoteServiceImpl;
import org.openelisglobal.note.valueholder.Note;
import org.openelisglobal.organization.service.OrganizationService;
import org.openelisglobal.referencetables.service.ReferenceTablesService;
import org.openelisglobal.referral.service.ReferralResultService;
import org.openelisglobal.referral.service.ReferralService;
import org.openelisglobal.referral.service.ReferralSetService;
import org.openelisglobal.referral.valueholder.Referral;
import org.openelisglobal.referral.valueholder.ReferralResult;
import org.openelisglobal.referral.valueholder.ReferralSet;
import org.openelisglobal.referral.valueholder.ReferralStatus;
import org.openelisglobal.reports.service.DocumentTrackService;
import org.openelisglobal.reports.service.DocumentTypeService;
import org.openelisglobal.reports.valueholder.DocumentTrack;
import org.openelisglobal.result.action.util.ResultSet;
import org.openelisglobal.result.service.ResultService;
import org.openelisglobal.result.valueholder.Result;
import org.openelisglobal.resultvalidation.bean.AnalysisItem;
import org.openelisglobal.resultvalidation.service.ResultValidationService;
import org.openelisglobal.resultvalidation.util.ResultValidationSaveService;
import org.openelisglobal.sample.service.SampleService;
import org.openelisglobal.sample.valueholder.Sample;
import org.openelisglobal.samplehuman.service.SampleHumanService;
import org.openelisglobal.spring.util.SpringContext;
import org.openelisglobal.testresult.service.TestResultService;
import org.openelisglobal.testresult.valueholder.TestResult;
import org.openelisglobal.typeoftestresult.service.TypeOfTestResultServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class FhirReferralServiceImpl implements FhirReferralService {

    @Autowired
    private ReferenceTablesService referenceTablesService;
    @Autowired
    private DocumentTrackService documentTrackService;
    @Autowired
    private DocumentTypeService documentTypeService;
    @Autowired
    private OrganizationService organizationService;
    @Autowired
    private SampleService sampleService;
    @Autowired
    private SampleHumanService sampleHumanService;
    @Autowired
    private ReferralResultService referralResultService;
    @Autowired
    private ReferralService referralService;
    @Autowired
    private ReferralSetService referralSetService;
    @Autowired
    private AnalysisService analysisService;
    @Autowired
    private FhirTransformService fhirTransformService;
    @Autowired
    private FhirPersistanceService fhirPersistanceService;
    @Autowired
    private ResultService resultService;
    @Autowired
    private ResultValidationService resultValidationService;
    @Autowired
    private DictionaryService dictionaryService;
    @Autowired
    private TestResultService testResultService;
    @Autowired
    private FhirConfig fhirConfig;
    @Value("${org.openelisglobal.remote.source.identifier:}#{T(java.util.Collections).emptyList()}")
    private List<String> remoteStoreIdentifier;

    private final String RESULT_SUBJECT = "Result Note";
    private String RESULT_TABLE_ID;
    private String RESULT_REPORT_ID;

    @PostConstruct
    public void setup() {
        RESULT_TABLE_ID = referenceTablesService.getReferenceTableByName("RESULT").getId();
        RESULT_REPORT_ID = documentTypeService.getDocumentTypeByName("resultExport").getId();
    }

//    @Override
//    @Transactional
//    public Bundle cancelReferralToOrganization(String referralOrganizationId, String sampleId,
//            List<String> analysisIds) throws FhirLocalPersistingException {
//        org.openelisglobal.organization.valueholder.Organization referralOrganization = organizationService
//                .get(referralOrganizationId);
//        Organization fhirOrg = getFhirOrganization(referralOrganization);
//        if (fhirOrg == null) {
//            // organization doesn't exist as fhir organization, cannot cancel automatically
//            return new Bundle();
//        }
//        Sample sample = sampleService.get(sampleId);
//        List<Analysis> analysises = analysisService.get(analysisIds);
//
//        List<ServiceRequest> serviceRequests = new ArrayList<>();
//        for (Analysis analysis : analysises) {
//            serviceRequests.add(fhirPersistanceService.getServiceRequestByAnalysisUuid(analysis.getFhirUuidAsString())
//                    .orElseThrow());
//        }
//
//        Task task = this.fhirPersistanceService.getTaskBasedOnServiceRequests(serviceRequests).orElseThrow();
//        task.setStatus(TaskStatus.CANCELLED);
//        return fhirPersistanceService.updateFhirResourceInFhirStore(task);
//    }

    @Override
    @Transactional
    public Bundle referAnalysisesToOrganization(Referral referral) throws FhirLocalPersistingException {
        String referralOrganizationId = referral.getOrganization().getId();
        String sampleId = referral.getAnalysis().getSampleItem().getSample().getId();
        String analysisId = referral.getAnalysis().getId();

        org.openelisglobal.organization.valueholder.Organization referralOrganization = organizationService
                .get(referralOrganizationId);
        Organization fhirOrg = getFhirOrganization(referralOrganization);
        if (fhirOrg == null) {
            LogEvent.logError(this.getClass().getName(), "referAnalysisesToOrganization",
                    "no fhir organization provided");
            // organization doesn't exist as fhir organization, cannot refer automatically
            return new Bundle();
        }
        Map<String, Resource> updateResources = new HashMap<>();
        Sample sample = sampleService.get(sampleId);

        Analysis analysis = analysisService.get(analysisId);
        ServiceRequest serviceRequest = fhirPersistanceService
                .getServiceRequestByAnalysisUuid(analysis.getFhirUuidAsString()).orElseThrow();
        Practitioner requester = fhirTransformService.transformNameToPractitioner(referral.getRequesterName());
        requester.setId(UUID.randomUUID().toString());
        Task task = createReferralTask(fhirOrg, fhirPersistanceService
                .getPatientByUuid(sampleHumanService.getPatientForSample(sample).getFhirUuidAsString()).orElseThrow(),
                serviceRequest, requester, sample);
        task.setId(referral.getFhirUuidAsString());
        updateResources.put(requester.getIdElement().getIdPart(), requester);
        updateResources.put(task.getIdElement().getIdPart(), task);

        return fhirPersistanceService.updateFhirResourcesInFhirStore(updateResources);
    }

    private Organization getFhirOrganization(org.openelisglobal.organization.valueholder.Organization organization) {
        return fhirPersistanceService.getFhirOrganizationByName(organization.getOrganizationName()).orElseThrow();
    }

    public Task createReferralTask(Organization referralOrganization, Patient patient, ServiceRequest serviceRequest,
            Practitioner requester, Sample sample) {
        Bundle bundle = new Bundle();
        Task task = new Task();
//        task.setGroupIdentifier(
//                new Identifier().setValue(labNumber).setSystem(fhirConfig.getOeFhirSystem() + "/samp_labNumber"));
        // TODO put the referral reason into the code
        task.setReasonCode(new CodeableConcept()
                .addCoding(new Coding().setSystem(fhirConfig.getOeFhirSystem() + "/refer_reason")));
        task.setOwner(fhirTransformService.createReferenceFor(referralOrganization));
        task.setRequester(fhirTransformService.createReferenceFor(requester));
        if (!remoteStoreIdentifier.isEmpty()) {
            task.setRestriction(new TaskRestrictionComponent()
                    .setRecipient(Arrays.asList(new Reference(remoteStoreIdentifier.get(0)))));
        }
        task.setAuthoredOn(new Date());
        task.setStatus(TaskStatus.REQUESTED);
        task.setFor(fhirTransformService.createReferenceFor(patient));
        task.setBasedOn(Arrays.asList(fhirTransformService.createReferenceFor(serviceRequest)));
        task.setFocus(fhirTransformService.createReferenceFor(serviceRequest));
        task.setDescription("referring accession number " + sample.getAccessionNumber() + " from "
                + task.getRequester().getReference() + " to " + task.getOwner().getReference());

        bundle.addEntry(new BundleEntryComponent().setResource(task));
        return task;
    }

    @Override
    @Transactional
    public void setReferralResult(ReferralResultsImportObjects resultsImport) {
        // TODO make this work for multiple service requests
        Analysis analysis = analysisService
                .getMatch("fhirUuid", UUID.fromString(
                        resultsImport.originalReferralObjects.serviceRequests.get(0).getIdElement().getIdPart()))
                .orElseThrow(() -> {
                    return new RuntimeException("no matching analysis with FhirUUID: "
                            + resultsImport.originalReferralObjects.serviceRequests.get(0).getIdElement().getIdPart());
                });
        List<Result> currentResults = resultService.getResultsByAnalysis(analysis);

        List<IResultUpdate> updaters = ValidationUpdateRegister.getRegisteredUpdaters();
        boolean areListeners = !updaters.isEmpty();
        // wrapper object for holding modifedResultSet and newResultSet
        IResultSaveService resultSaveService = new ResultValidationSaveService();

        List<AnalysisItem> resultItemList = new ArrayList<>();
        List<Analysis> analysisUpdateList = new ArrayList<>();
        ArrayList<Sample> sampleUpdateList = new ArrayList<>();
        ArrayList<Note> noteUpdateList = new ArrayList<>();
        ArrayList<Result> resultUpdateList = new ArrayList<>();
        List<Result> deletableList = new ArrayList<>();
        List<ReferralSet> referralSets = new ArrayList<>();

        AnalysisItem analysisItem = new AnalysisItem();

        analysisItem.setAccessionNumber(analysis.getSampleItem().getSample().getAccessionNumber());
        resultItemList.add(analysisItem);

        analysis.setStatusId(SpringContext.getBean(IStatusService.class).getStatusID(AnalysisStatus.Finalized));
        analysis.setEnteredDate(DateUtil.getNowAsTimestamp());
        analysis.setReleasedDate(DateUtil.getNowAsSqlDate());
        analysis.setSysUserId("1");

        analysisUpdateList.add(analysis);

//        createNeededNotes(analysisItem, analysis, noteUpdateList);

        for (Observation observation : resultsImport.observations) {
            Result result = getResultFromObservation(observation, currentResults, analysis);
            resultUpdateList.add(result);
            if (areListeners) {
                addResultSets(analysis, result, resultSaveService);
            }
            recordResultForReferral(resultsImport, analysis, result, referralSets);
        }

        try {
            referralSetService.updateReferralSets(referralSets, new ArrayList<>(), new HashSet<>(), new ArrayList<>(),
                    "1");
            resultValidationService.persistdata(new ArrayList<>(), analysisUpdateList, resultUpdateList, resultItemList,
                    sampleUpdateList, noteUpdateList, resultSaveService, new ArrayList<>(), "1");
            fhirTransformService.transformPersistResultValidationFhirObjects(deletableList, analysisUpdateList,
                    resultUpdateList, resultItemList, sampleUpdateList, noteUpdateList);
            resultsImport.originalReferralObjects.task.setStatus(TaskStatus.COMPLETED);
            fhirPersistanceService.updateFhirResourceInFhirStore(resultsImport.originalReferralObjects.task);
        } catch (FhirPersistanceException e) {
            LogEvent.logError(e);
        }

    }

    private Result getResultFromObservation(Observation observation, List<Result> currentResults, Analysis analysis) {
        Result result = new Result();
        if (currentResults.size() == 1) {
            result = currentResults.get(0);
        } else {
            result = new Result();
            TestResult testResult = result.getTestResult();
            String testResultType = testResult.getTestResultType();
            result.setResultType(testResultType);
            result.setAnalysis(analysis);
            currentResults.stream().forEach(e -> {
                resultService.delete(e);
            });
        }

        if (TypeOfTestResultServiceImpl.ResultType.isMultiSelectVariant(result.getResultType())
                || TypeOfTestResultServiceImpl.ResultType.isDictionaryVariant(result.getResultType())) {
            String inferredValue = ((CodeableConcept) observation.getValue()).getCodingFirstRep().getCode();
            List<TestResult> testResults = testResultService
                    .getAllActiveTestResultsPerTest(analysisService.getTest(analysis));
            String resultValue = null;
            for (TestResult testResult : testResults) {
                if (StringUtils.equals(inferredValue, dictionaryService.get(testResult.getValue()).getDictEntry())) {
                    LogEvent.logDebug(this.getClass().getName(), "setReferralResult",
                            "found a matching dictionary value for '" + inferredValue + "'");
                    resultValue = dictionaryService.get(testResult.getValue()).getId();
                    result.setValue(resultValue);
                }
            }
            if (resultValue == null) {
                LogEvent.logDebug(this.getClass().getName(), "setReferralResult",
                        "no matching dictionary value for '" + inferredValue + "'");
            }
        } else if (TypeOfTestResultServiceImpl.ResultType.isNumeric(result.getResultType())) {
            result.setValue(((Quantity) observation.getValue()).getValue().toPlainString());
        } else if (TypeOfTestResultServiceImpl.ResultType.isTextOnlyVariant(result.getResultType())) {
            result.setValue(((StringType) observation.getValue()).getValueAsString());
        }

        result.setSysUserId("1");
        return result;
    }

    private void addResultSets(Analysis analysis, Result result, IResultSaveService resultValidationSave) {
        Sample sample = analysis.getSampleItem().getSample();
        org.openelisglobal.patient.valueholder.Patient patient = sampleHumanService.getPatientForSample(sample);
        if (finalResultAlreadySent(result)) {
            result.setResultEvent(Event.CORRECTION);
            resultValidationSave.getModifiedResults()
                    .add(new ResultSet(result, null, null, patient, sample, null, false));
        } else {
            result.setResultEvent(Event.FINAL_RESULT);
            resultValidationSave.getNewResults().add(new ResultSet(result, null, null, patient, sample, null, false));
        }
    }

    // TO DO bug falsely triggered when preliminary result is sent, fails, retries
    // and succeeds
    private boolean finalResultAlreadySent(Result result) {
        List<DocumentTrack> documents = documentTrackService.getByTypeRecordAndTable(RESULT_REPORT_ID, RESULT_TABLE_ID,
                result.getId());
        return documents.size() > 0;
    }

    private void recordResultForReferral(ReferralResultsImportObjects resultsImport, Analysis analysis, Result result,
            List<ReferralSet> referralSets) {

        ReferralSet referralSet = new ReferralSet();

        Referral referral = referralService.getReferralByAnalysisId(analysis.getId());
        referral.setStatus(ReferralStatus.RECEIVED);
        List<ReferralResult> referralResults = referralResultService.getReferralResultsForReferral(referral.getId());
        referralSet.setExistingReferralResults(referralResults == null ? new ArrayList<>() : referralResults);
        ReferralResult referralResult = referralSet.getNextReferralResult();
        referralResult.setSysUserId("1");
        referralResult.setReferralId(referral.getId());
        referralResult.setReferralReportDate(DateUtil.getNowAsTimestamp());
        referralResult.setTestId(analysis.getTest().getId());
        referralResult.setResult(result);

        NoteService noteService = SpringContext.getBean(NoteService.class);
        referralSet.setNote(noteService.createSavableNote(referral.getAnalysis(), NoteServiceImpl.NoteType.INTERNAL,
                "referral result imported automatically", RESULT_SUBJECT, "1"));
        referralSet.setReferral(referral);

        referralSets.add(referralSet);
    }

}
