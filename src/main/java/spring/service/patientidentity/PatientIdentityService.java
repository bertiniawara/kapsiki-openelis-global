package spring.service.patientidentity;

import java.util.List;

import spring.service.common.BaseObjectService;
import us.mn.state.health.lims.patientidentity.valueholder.PatientIdentity;

public interface PatientIdentityService extends BaseObjectService<PatientIdentity, String> {

	List<PatientIdentity> getPatientIdentitiesForPatient(String id);

	PatientIdentity getPatitentIdentityForPatientAndType(String patientId, String identityTypeId);

	List<PatientIdentity> getPatientIdentitiesByValueAndType(String value, String identityType);
}