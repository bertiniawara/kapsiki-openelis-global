<%@ page language="java" contentType="text/html; charset=utf-8"
         import="us.mn.state.health.lims.common.action.IActionConstants,
	            us.mn.state.health.lims.common.util.*,
	            us.mn.state.health.lims.common.util.ConfigurationProperties.Property,
	            us.mn.state.health.lims.login.dao.UserModuleDAO,
	            us.mn.state.health.lims.login.daoimpl.UserModuleDAOImpl,
	            java.util.HashSet,
	            org.owasp.encoder.Encode"%>
<%@ page isELIgnored="false" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form"%>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="app" uri="/tags/labdev-view" %>
<%@ taglib prefix="ajax" uri="/tags/ajaxtags" %>

<%@ taglib uri="http://tiles.apache.org/tags-tiles" prefix="tiles"%>


<c:set var="formName" value="${form.formName}" />
<c:set var="requestType" value="${type}" />
<c:set var="genericDomain" value="" />
<%--       
<bean:define id="requestType" value='<%=(String)request.getSession().getAttribute("type")%>' />
<bean:define id="idSeparator"   value='<%=SystemConfiguration.getInstance().getDefaultIdSeparator()%>' />
<bean:define id="accessionFormat" value='<%=ConfigurationProperties.getInstance().getPropertyValue(Property.AccessionFormat)%>' />
<bean:define id="genericDomain" value='' /> --%>


<%!
    String basePath = "";
    UserModuleDAO userModuleDAO = new UserModuleDAOImpl();
    String requestType;
%>
<%
	requestType = (String) request.getAttribute("type");
    String path = request.getContextPath();
    basePath = request.getScheme() + "://" + request.getServerName() + ":"  + request.getServerPort() + path + "/";
    HashSet accessMap = (HashSet)request.getSession().getAttribute(IActionConstants.PERMITTED_ACTIONS_MAP);
    boolean isAdmin = userModuleDAO.isUserAdmin(request);
    // no one should edit patient numbers at this time.  PAH 11/05/2010
    boolean canEditPatientSubjectNos =  isAdmin || accessMap.contains(IActionConstants.MODULE_ACCESS_PATIENT_SUBJECTNOS_EDIT);
    boolean canEditAccessionNo = isAdmin || accessMap.contains(IActionConstants.MODULE_ACCESS_SAMPLE_ACCESSIONNO_EDIT);
%>

<script type="text/javascript" src="<%=basePath%>scripts/utilities.js?ver=<%= Versioning.getBuildNumber() %>" ></script>
<script type="text/javascript" src="<%=basePath%>scripts/retroCIUtilities.js?ver=<%= Versioning.getBuildNumber() %>" ></script>
<script type="text/javascript" src="<%=basePath%>scripts/entryByProjectUtils.js?ver=<%= Versioning.getBuildNumber() %>"></script>

<script type="text/javascript">

var dirty = false;
var type = '<%=Encode.forJavaScript(requestType)%>';
var requestType = '<%=Encode.forJavaScript(requestType)%>';
var pageType = "Sample";
birthDateUsageMessage = "<spring:message code='error.dob.complete.less.two.years'/>";
previousNotMatchedMessage = "<spring:message code='error.2ndEntry.previous.not.matched'/>";
noMatchFoundMessage = "<spring:message code='patient.message.patientNotFound'/>";
saveNotUnderInvestigationMessage = "<spring:message code='patient.project.conflicts.saveNotUnderInvestigation'/>";
testInvalid = "<spring:message code='error.2ndEntry.test.invalid'/>";
blankTextField = "<spring:message code='blank.text.field'/>";

var canEditPatientSubjectNos = <%= canEditPatientSubjectNos %>;
var canEditAccessionNo = <%= canEditAccessionNo %>;

function  /*void*/ setMyCancelAction(form, action, validate, parameters)
{
    //first turn off any further validation
    setAction(window.document.forms[0], 'Cancel', 'no', '');
}

function Studies() {
    this.validators = new Array();
    this.studyNames = ["InitialARV_Id", "FollowUp_ARV_Id", "RTN_Id", "EID_Id", "VL_Id",  "Indeterminate_Id", "Special_Request_Id"];

    this.validators["InitialARV_Id"] = new FieldValidator();
    this.validators["InitialARV_Id"].setRequiredFields( new Array("iarv.labNo", "iarv.receivedDateForDisplay", "iarv.interviewDate", "iarv.centerCode", "subjectOrSiteSubject", "iarv.gender", "iarv.dateOfBirth") );

    this.validators["FollowUpARV_Id"] = new FieldValidator();
    this.validators["FollowUpARV_Id"].setRequiredFields( new Array("farv.labNo", "farv.receivedDateForDisplay", "farv.interviewDate", "farv.centerCode", "subjectOrSiteSubject", "farv.gender", "farv.dateOfBirth") );

    this.validators["RTN_Id"] = new FieldValidator();
    this.validators["RTN_Id"].setRequiredFields( new Array("rtn.labNo", "rtn.receivedDateForDisplay", "rtn.interviewDate", "rtn.gender", "rtn.dateOfBirth") );

    // this.validators["EID_Id"] = new FieldValidator();
    this.validators["Indeterminate_Id"] = new FieldValidator();
    this.validators["Indeterminate_Id"].setRequiredFields( new Array("ind.labNo", "ind.receivedDateForDisplay", "ind.interviewDate", "subjectOrSiteSubject", "ind.centerName", "ind.dateOfBirth", "ind.gender") );

    this.validators["Special_Request_Id"] = new FieldValidator();
    this.validators["Special_Request_Id"].setRequiredFields( new Array("spe.labNo", "spe.receivedDateForDisplay", "spe.interviewDate", "subjectOrSiteSubject", "spe.gender") );


    this.getValidator = function /*FieldValidator*/ (divId) {
        return this.validators[divId];
    }

    this.projectChecker = new Array();

    this.initializeProjectChecker = function () {
        this.projectChecker["InitialARV_Id"] = iarv;
        this.projectChecker["FollowUpARV_Id"] = farv;
        this.projectChecker["RTN_Id"] = rtn;
        //this.projectChecker["EID_Id"] = eid;
        this.projectChecker["Indeterminate_Id"] = ind;
        this.projectChecker["Special_Request_Id"] = spe;
    }

    this.getProjectChecker = function (divId) {
        this.initializeProjectChecker(); // not clear why a navigating back to this page makes field checkers empty, so we'll always load.
        return this.projectChecker[divId];
    }
}


studies = new Studies();
projectChecker = null;

function /*void*/ makeDirty(){
    dirty=true;
    if( typeof(showSuccessMessage) != 'undefinded' ){
        showSuccessMessage(false); //refers to last save
    }
    // Adds warning when leaving page if content has been entered into makeDirty form fields
    function formWarning(){ 
    return "<spring:message code="banner.menu.dataLossWarning"/>";
    }
    window.onbeforeunload = formWarning;
}

/*
 * Set default tests by study, but 
 */
function setDefaultTests( div )
{
    if ( requestType != 'initial' ) {
        return;
    }
    var tests = new Array();
    if (div=="InitialARV_Id") {
       /* tests = new Array("iarv.serologyHIVTest", "iarv.glycemiaTest", "iarv.creatinineTest",
                "iarv.transaminaseTest", "iarv.edtaTubeTaken", "iarv.dryTubeTaken",
                "iarv.nfsTest", "iarv.cd4cd8Test") ;*/
                
    	tests = new Array("iarv.serologyHIVTest", "iarv.creatinineTest",
                "iarv.edtaTubeTaken", "iarv.dryTubeTaken",
                "iarv.nfsTest", "iarv.cd4cd8Test") ;      
      }
    
    if (div=="FollowUpARV_Id") {
       // tests = new Array("farv.glycemiaTest", "farv.creatinineTest",
             //  "farv.transaminaseTest", "farv.edtaTubeTaken", "farv.dryTubeTaken") ;
       tests = new Array("farv.creatinineTest", "farv.dryTubeTaken") ;
    }
    //if (div=="EID_Id") {
    //  tests = new Array ("eid.dnaPCR", "eid.dbsTaken");
    //}
    if (div=="RTN_Id" ) {
        tests = new Array ("rtn.serologyHIVTest", "rtn.dryTubeTaken");
    }
    if (div=="Indeterminate_Id" ){
            tests = new Array ("ind.serologyHIVTest", "ind.dryTubeTaken");
    }

    for( var i = 0; i < tests.length; i++ ){
        var testId = tests[i];
        $(testId).value = true;
        $(testId).checked = true;
    }
}

function initializeStudySelection() {
    selectStudy($('projectFormName').value);
}

function selectStudy( divId ) {
    var i = getSelectIndexFor("studyFormsId", divId);
    document.forms[0].studyForms.selectedIndex = i;
    switchStudyForm( divId );
}

function switchStudyForm( divId ){
    hideAllDivs();
    if (divId != "" && divId != "0") {
        $("projectFormName").value = divId;
        switch (divId) {
        case "EID_Id":
            //location.replace("SampleEntryByProject.do?type=initial");
            savePage__("SampleEntryByProject.do?type=" + type);
            return;
        case "VL_Id":
            //location.replace("SampleEntryByProject.do?type=initial");
            savePage__("SampleEntryByProject.do?type=" + type);
            return;
        }
        toggleDisabledDiv(document.getElementById(divId), true);
        //document.forms[0].project.value = divId;
        document.getElementById(divId).style.display = "block";
        fieldValidator = studies.getValidator(divId); // reset the page fieldValidator for all fields to use.
        projectChecker = studies.getProjectChecker(divId);
        projectChecker.setSubjectOrSiteSubjectEntered();                
        adjustFieldsForRequestType();
        setDefaultTests(divId);
        setSaveButton();
    }
}
function adjustFieldsForRequestType()  {
    switch (requestType) {
    case "initial":
        break;
    case "verify":
        break;
    }
}

function hideAllDivs(){
    toggleDisabledDiv(document.getElementById("InitialARV_Id"), false);
    toggleDisabledDiv(document.getElementById("FollowUpARV_Id"), false);
    toggleDisabledDiv(document.getElementById("RTN_Id"), false);
    //toggleDisabledDiv(document.getElementById("EID_Id"), false);
    toggleDisabledDiv(document.getElementById("Indeterminate_Id"), false);
    toggleDisabledDiv(document.getElementById("Special_Request_Id"), false);

    document.getElementById('InitialARV_Id').style.display = "none";
    document.getElementById('FollowUpARV_Id').style.display = "none";
    document.getElementById('RTN_Id').style.display = "none";
    //document.getElementById('EID_Id').style.display = "none";
    document.getElementById('Indeterminate_Id').style.display = "none";
    document.getElementById('Special_Request_Id').style.display = "none";
}

function /*boolean*/ allSamplesHaveTests(){
    // based on studyType, check that at least one test is chosen
    // TODO PAHill this check is done on the server, but could be done here also.
}

function  /*void*/ savePage__(action) {
    window.onbeforeunload = null; // Added to flag that formWarning alert isn't needed.
    var form = window.document.forms[0];
    if (action == null) {
        action = "SampleEntryByProjectSave.do?type=" + type
    }
    form.action = action;
    form.submit();
}

function /*void*/ setSaveButton() {
    var validToSave = fieldValidator.isAllValid();

    $("saveButtonId").disabled = !validToSave;
    
}

</script>

<form:hidden path="currentDate" id="currentDate"/>
<form:hidden path="domain" value="${genericDomain}" id="domain"/>
<form:hidden path="project" id="project"/>
<form:hidden path="patientLastUpdated" id="patientLastUpdated" />
<form:hidden path="personLastUpdated" id="personLastUpdated"/>
<form:hidden path="patientProcessingStatus" id="processingStatus" value="add" />
<form:hidden path="patientPK" id="patientPK" />
<form:hidden path="samplePK" id="samplePK" />
<form:hidden path="observations.projectFormName" id="projectFormName"/>
<form:hidden path=""  id="subjectOrSiteSubject" value="" />

<b><spring:message code="sample.entry.project.form"/></b>
<select name="studyForms" onchange="switchStudyForm(this.value);" id="studyFormsId">
    <option value="0" selected> </option>
    <option value="InitialARV_Id" ><spring:message code="sample.entry.project.initialARV.title"/></option>
    <option value="FollowUpARV_Id" ><spring:message code="sample.entry.project.followupARV.title"/></option>
    <option value="RTN_Id" ><spring:message code="sample.entry.project.RTN.title"/></option>
    <option value="EID_Id" ><spring:message code="sample.entry.project.EID.title"/></option>
    <option value="Indeterminate_Id" ><spring:message code="sample.entry.project.indeterminate.title"/></option>
    <option value="Special_Request_Id"><spring:message code="sample.entry.project.specialRequest.title"/></option>
    <option value="VL_Id" ><spring:message code="sample.entry.project.VL.title"/></option>
</select>
<br/>
<hr>

<div id="studies">
<div id="InitialARV_Id" style="display:none;">
    <h2><spring:message code="sample.entry.project.initialARV.title"/></h2>
    <table width="100%">
        <tr >
            <td class="required" width="2%">*</td>
            <td width="28%">
                <spring:message code="sample.entry.project.ARV.centerName" />
            </td>
            <td width="70%">
            	<form:select path="ProjectData.ARVcenterName"
            				 id="iarv.centerName"
                             onchange="iarv.checkCenterName(true)">
                             <form:options items="${organizationTypeLists.ARV_ORGS_BY_NAME.list}" itemValue="id" itemLabel="organizationName"/>
                </form:select>
                             
                <%-- <form:select
                             path="ProjectData.ARVcenterName"
                             id="iarv.centerName"
                             onchange="iarv.checkCenterName(true)">
                    <form:options
                        path="organizationTypeLists.ARV_ORGS_BY_NAME.list"
                        itemLabel="organizationName"
                        itemalue="id" />
                </form:select> --%>
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="patient.project.centerCode" />
            </td>
            <td>
            	<form:select path="ProjectData.ARVcenterCode"
            				 id="iarv.centerCode"
                             onchange="iarv.checkCenterCode(true)">
                             <form:options items="${organizationTypeLists.ARV_ORGS.list}" itemValue="id" itemLabel="doubleName"/>
                </form:select>
               <%--  <form:select
                             path="ProjectData.ARVcenterCode"
                             id="iarv.centerCode"
                             onchange="iarv.checkCenterCode(true)">
                    <form:options
                        path="organizationTypeLists.ARV_ORGS.list" itemLabel="doubleName"
                        itemalue="id" />
                </form:select> --%>
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message code="sample.entry.project.doctor"/>
            </td>
            <td>
            <form:input path="observations.nameOfDoctor"
            			cssClass="text"
            			id="iarv.nameOfDoctor"
            			size="50"
            			onchange="compareAllObservationHistoryFields(true)"/>
            <%-- <form:input path="observations.nameOfDoctor"
                        cssClass="text"
                        id="iarv.nameOfDoctor" size="50"
                        onchange="compareAllObservationHistoryFields(true)"/> --%>
            </td>
            <div id="iarv.nameOfDoctorMessage" class="blank"></div>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="sample.entry.project.receivedDate"/>&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
            <form:input path="receivedDateForDisplay"
            			cssClass="text"
	                    onkeyup="addDateSlashes(this, event);"
	                    onchange="iarv.checkReceivedDate(false);"
	                    id="iarv.receivedDateForDisplay" maxlength="10"/>
            <%-- <form:input
                    path="receivedDateForDisplay"
                    onkeyup="addDateSlashes(this, event);"
                    onchange="iarv.checkReceivedDate(false);"
                    cssClass="text"
                    id="iarv.receivedDateForDisplay" maxlength="10"/> --%>
                    <div id="iarv.receivedDateForDisplayMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                 <spring:message code="sample.entry.project.receivedTime" />&nbsp;<spring:message code="sample.military.time.format"/>
            </td>
            <td>
            <form:input path="receivedTimeForDisplay"
                onkeyup="filterTimeKeys(this, event);"                 
                onblur="iarv.checkReceivedTime(true);"
                cssClass="text"
                id="iarv.receivedTimeForDisplay" maxlength="5"/>
            <%-- <form:input
                path="receivedTimeForDisplay"   
                onkeyup="filterTimeKeys(this, event);"                 
                onblur="iarv.checkReceivedTime(true);"
                cssClass="text"
                id="iarv.receivedTimeForDisplay" maxlength="5"/> --%>
                <div id="iarv.receivedTimeForDisplayMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="sample.entry.project.dateTaken"/>&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
            <form:input path="interviewDate"
                    onkeyup="addDateSlashes(this, event);"
                    onchange="iarv.checkInterviewDate(false)"
                    cssClass="text"
                    id="iarv.interviewDate" maxlength="10"/>
            <%-- <form:input
                    path="interviewDate"
                    onkeyup="addDateSlashes(this, event);"
                    onchange="iarv.checkInterviewDate(false)"
                    cssClass="text"
                    id="iarv.interviewDate" maxlength="10"/>
                    <div id="iarv.interviewDateMessage" class="blank" /> --%>
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message code="sample.entry.project.timeTaken"/>&nbsp;<spring:message code="sample.military.time.format"/>
            </td>
            <td>
            <form:input path="interviewTime"
                    onkeyup="filterTimeKeys(this, event);"              
                    onblur="iarv.checkInterviewTime(true);"
                    cssClass="text"
                    id="iarv.interviewTime" maxlength="5"/>
            <%-- <form:input
                    path="interviewTime"
                    onkeyup="filterTimeKeys(this, event);"              
                    onblur="iarv.checkInterviewTime(true);"
                    cssClass="text"
                    id="iarv.interviewTime" maxlength="5"/> --%>
                    <div id="iarv.interviewTimeMessage" class="blank" />
            </td>
        </tr>       
        <tr>
            <td class="required">+</td>
            <td><spring:message code="sample.entry.project.subjectNumber"/></td>
            <td>
            <form:input path="subjectNumber"
                        id="iarv.subjectNumber"
                        cssClass="text"
                        maxlength="7"
                        onchange="iarv.checkSubjectNumber(true)"/>
                <%-- <form:input
                        path="subjectNumber"
                        id="iarv.subjectNumber"
                        cssClass="text"
                        maxlength="7"
                        onchange="iarv.checkSubjectNumber(true)"/>
                <div id="iarv.subjectNumberMessage" class="blank" /> --%>
            </td>
        </tr>
        <tr>
            <td class="required">+</td>
            <td><spring:message code="patient.site.subject.number"/></td>
            <td>
            <form:input path="siteSubjectNumber"
                        id="iarv.siteSubjectNumber"
                        cssClass="text"
                        onchange="iarv.checkSiteSubjectNumber(true);"/>
                <%-- <form:input
                        path="siteSubjectNumber"
                        id="iarv.siteSubjectNumber"
                        cssClass="text"
                        onchange="iarv.checkSiteSubjectNumber(true);"/> --%>
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <%=StringUtil.getContextualMessageForKey("quick.entry.accession.number")%>
            </td>
            <td>
                <div class="blank"><spring:message code="sample.entry.project.LART"/></div>
                <INPUT type="text" name="iarv.labNoForDisplay" id="iarv.labNoForDisplay" size="5" class="text"
                    onchange="handleLabNoChange( this, '<spring:message code="sample.entry.project.LART"/>', 'false' );makeDirty();"
                    maxlength="5" />
            <form:input path="labNo"
                        cssClass="text"
                        style="display:none;"
                        id="iarv.labNo" />
                <%-- <form:input path="labNo"
                        cssClass="text"
                        style="display:none;"
                        id="iarv.labNo" /> --%>
                <div id="iarv.labNoMessage" class="blank"  ></div>
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message  code="patient.gender" />
            </td>
            <td>
            <form:select path="gender"
                         id="iarv.gender"
                         onchange="iarv.checkGender(true)">
            <form:options items="${genders}" itemLabel="localizedName" itemValue="genderType"/>
            </form:select>
               <%--  <form:select
                         path="gender"
                         id="iarv.gender"
                         onchange="iarv.checkGender(true)">
                <form:options path="genders"
                    itemLabel="localizedName" value="genderType" />
                </form:select> --%>
                <div id="iarv.genderMessage" class="blank" />
            </td>
        </tr>

        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
                <form:input
                      path="birthDateForDisplay"
                      cssClass="text"
                      size="20"
                      maxlength="10"
                      onkeyup="addDateSlashes(this, event);"
                      onchange="iarv.checkDateOfBirth(false)"
                      id="iarv.dateOfBirth" />
                <div id="iarv.dateOfBirthMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td ></td>
            <td>
                <spring:message  code="patient.age" />
            </td>
            <td>
                <label for="iarv.age" ><spring:message  code="label.year" /></label>
                <INPUT type="text" name="ageYear" id="iarv.age" size="3"
                    onchange="iarv.checkAge( this, true, 'year' );"
                    maxlength="2" />
                <div id="ageMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td colspan="3" class="sectionTitle">
                <spring:message  code="sample.entry.project.title.specimen" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.ARV.dryTubeTaken" /></td>
            <td>

                <form:checkbox
                       path="ProjectData.dryTubeTaken"
                       id="iarv.dryTubeTaken"
                       onchange="iarv.checkSampleItem(this);"/>
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.ARV.edtaTubeTaken" /></td>
            <td>
                <form:checkbox
                       path="ProjectData.edtaTubeTaken"
                       id="iarv.edtaTubeTaken"
                       onchange="iarv.checkSampleItem(this);"/>
            </td>
        </tr>
        <tr>
            <td></td>
            <td colspan="3" class="sectionTitle">
                <spring:message  code="sample.entry.project.title.dryTube" />
            </td>
        </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.serologyHIVTest" /></td>
                <td>

                    <form:checkbox
                           path="ProjectData.serologyHIVTest"
                           id="iarv.serologyHIVTest"
                           onchange="iarv.checkSampleItem($('iarv.dryTubeTaken'), this)"/>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.glycemiaTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.glycemiaTest"
                           id="iarv.glycemiaTest"
                           onchange="iarv.checkSampleItem($('iarv.dryTubeTaken'), this)"/>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.creatinineTest" /></td>
                <td>
                    <form:checkbox
                                path="ProjectData.creatinineTest"
                                id="iarv.creatinineTest"
                                onchange="iarv.checkSampleItem($('iarv.dryTubeTaken'), this);" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.transaminaseTest" /></td>
                <td>
                    <form:checkbox
                                path="ProjectData.transaminaseTest"
                                id="iarv.transaminaseTest"
                                onchange="iarv.checkSampleItem($('iarv.dryTubeTaken'), this)" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td colspan="3" class="sectionTitle">
                    <spring:message  code="sample.entry.project.title.edtaTube" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.nfsTest" /></td>
                <td>
                    <form:checkbox
                                path="ProjectData.nfsTest"
                                id="iarv.nfsTest"
                                onchange="iarv.checkSampleItem($('iarv.edtaTubeTaken'), this)" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.cd4cd8Test" /></td>
                <td>
                    <form:checkbox
                                path="ProjectData.cd4cd8Test"
                                id="iarv.cd4cd8Test"
                                onchange="iarv.checkSampleItem($('iarv.edtaTubeTaken'), this)" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td colspan="3" class="sectionTitle">
                    <spring:message  code="sample.entry.project.title.otherTests" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.viralLoadTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.viralLoadTest"
                           id="iarv.viralLoadTest"
                           onchange="iarv.checkSampleItem($('iarv.edtaTubeTaken'), this);" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.genotypingTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.genotypingTest"
                           id="iarv.genotypingTest"
                           onchange="iarv.checkSampleItem($('iarv.edtaTubeTaken'), this)" />
                </td>
            </tr>
            <tr><td colspan="6"><hr/></td></tr>
            <tr id="iarv.underInvestigationRow">
                <td class="required"></td>
                <td>
                    <spring:message code="patient.project.underInvestigation" />
                </td>
                <td>
                    <form:select
                    path="observations.underInvestigation" onchange="makeDirty();compareAllObservationHistoryFields(true)"
                    id="iarv.underInvestigation">
                    <form:options
                        path="dictionaryLists.YES_NO.list" itemLabel="localizedName"
                        itemalue="id" />
                    </form:select>
                </td>
            </tr>
            <tr id="iarv.underInvestigationCommentRow">
                <td class="required"></td>
                <td>
                    <spring:message code="patient.project.underInvestigationComment" />
                </td>
                <td colspan="3">
                    <form:input path="ProjectData.underInvestigationNote" maxlength="1000" size="80"
                        onchange="makeDirty();" id="iarv.underInvestigationComment" />
                </td>
            </tr>
    </table>

</div>
<div id="FollowUpARV_Id" style="display:none;">
    <h2><spring:message code="sample.entry.project.followupARV.title"/></h2>
    <table width="100%">
        <tr>
            <td class="required" width="2%">*</td>
            <td width="28%">
                <spring:message code="sample.entry.project.ARV.centerName" />
            </td>
            <td width="70%">
                <form:select
                             path="ProjectData.ARVcenterName"
                             id="farv.centerName"
                             onchange="farv.checkCenterName(true)">
                    <form:options
                        path="organizationTypeLists.ARV_ORGS_BY_NAME.list"
                        itemLabel="organizationName"
                        itemalue="id" />
                </form:select>
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="patient.project.centerCode" />
            </td>
            <td>
                <form:select
                             path="ProjectData.ARVcenterCode"
                             id="farv.centerCode"
                             onchange="farv.checkCenterCode(true)">
                    <form:options
                        path="organizationTypeLists.ARV_ORGS.list" itemLabel="doubleName"
                        itemalue="id" />
                </form:select>
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message code="sample.entry.project.doctor"/>
            </td>
            <td>
            <form:input path="observations.nameOfDoctor"
                        cssClass="text"
                        id="farv.nameOfDoctor" size="50"
                        onchange="compareAllObservationHistoryFields(true)" />
            </td>
        </tr>

        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="sample.entry.project.receivedDate"/>&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
            <form:input
                    path="receivedDateForDisplay"
                    cssClass="text"
                    id="farv.receivedDateForDisplay" maxlength="10"
                    onkeyup="addDateSlashes(this, event);"
                    onchange="farv.checkReceivedDate(false);" />
                    <div id="farv.receivedDateForDisplayMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message code="sample.entry.project.receivedTime"/>&nbsp;<spring:message code="sample.military.time.format"/>
            </td>
            <td>
            <form:input
                    path="receivedTimeForDisplay"
                    cssClass="text"
                    onkeyup="filterTimeKeys(this, event);"
                    id="farv.receivedTimeForDisplay" maxlength="5"                    
                    onblur="farv.checkReceivedTime(true);" />
                    <div id="farv.receivedTimeForDisplayMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="sample.entry.project.dateTaken"/>&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
            <form:input
                    path="interviewDate"
                    onkeyup="addDateSlashes(this, event);"
                    onchange="farv.checkInterviewDate(false)"
                    cssClass="text"
                    id="farv.interviewDate" maxlength="10"/>
                    <div id="farv.interviewDateMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message code="sample.entry.project.timeTaken"/>&nbsp;<spring:message code="sample.military.time.format"/>
            </td>
            <td>
            <form:input
                    path="interviewTime"
                    onkeyup="filterTimeKeys(this, event);"                 
                    onblur="farv.checkInterviewTime(true);"
                    cssClass="text"
                    id="farv.interviewTime" maxlength="5"/>
                    <div id="farv.interviewTimeMessage" class="blank" />
            </td>
        </tr>       
       
        <tr>
            <td class="required">+</td>
            <td><spring:message code="sample.entry.project.subjectNumber"/></td>
            <td>
                <form:input
                        path="subjectNumber"
                        id="farv.subjectNumber"
                        cssClass="text"
                        maxlength="7"
                        onchange="farv.checkSubjectNumber(true);" />
                <div id="farv.subjectNumberMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td class="required">+</td>
            <td><spring:message code="patient.site.subject.number"/></td>
            <td>
                <form:input
                        path="siteSubjectNumber"
                        id="farv.siteSubjectNumber"
                        cssClass="text"
                        onchange="farv.checkSiteSubjectNumber(true);" />
                <div id="farv.siteSubjectNumberMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <%=StringUtil.getContextualMessageForKey("quick.entry.accession.number")%>

            </td>
            <td>
                <div class="blank"><spring:message code="sample.entry.project.LART"/></div>
                <INPUT type=text name="farv.labNoForDisplay" id="farv.labNoForDisplay" size="5" class="text"
                    onchange="handleLabNoChange( this, '<spring:message code="sample.entry.project.LART"/>', false );makeDirty();"
                    maxlength="5" />
                <form:input path="labNo"
                        cssClass="text" style="display:none;"
                        id="farv.labNo" />
                <div id="farv.labNoMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message  code="patient.gender" />
            </td>
            <td>
                <form:select
                         path="gender"
                         id="farv.gender"
                         onchange="farv.checkGender(false)" >
                    <form:options path="genders"
                        itemLabel="localizedName" value="genderType" />
                </form:select>
                <div id="farv.genderIDMessage" class="blank" />
            </td>
        </tr>

        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
                <form:input
                      path="birthDateForDisplay"
                      cssClass="text"
                      size="20"
                      maxlength="10"
                      id="farv.dateOfBirth"
                      onkeyup="addDateSlashes(this, event);"
                      onchange="farv.checkDateOfBirth(false)" />
                <div id="farv.dateOfBirthMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td ></td>
            <td>
                <spring:message  code="patient.age" />
            </td>
            <td>
                <label for="farv.age" ><spring:message  code="label.year" /></label>
                <INPUT type="text" name="ageYear" id="farv.age" size="3"
                    onchange="farv.checkAge( this, true, 'year' );"
                    maxlength="2" />
                <div id="ageMessage" class="blank" ></div>
            </td>
        </tr>
        <tr >
            <td></td>
            <td>
                <spring:message code="patient.project.hivStatus" />
            </td>
            <td>
                <form:select
                         path="observations.hivStatus"
                         onchange="farv.checkHivStatus(true);"
                         id="farv.hivStatus"  >
                    <form:options path="ProjectData.hivStatusList"
                        itemLabel="localizedName" itemalue="id" />
                </form:select>
                <div id="farv.hivStatusMessage" class="blank"></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td colspan="3" class="sectionTitle">
                <spring:message  code="sample.entry.project.title.specimen" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.ARV.dryTubeTaken" /></td>
            <td>

                <form:checkbox
                                path="ProjectData.dryTubeTaken"
                                id="farv.dryTubeTaken"
                                onchange="farv.checkSampleItem(this)" />
                <div id="farv.dryTubeTakenMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.ARV.edtaTubeTaken" /></td>
            <td>
                <form:checkbox
                            path="ProjectData.edtaTubeTaken"
                            id="farv.edtaTubeTaken"
                            onchange="farv.checkSampleItem(this);"/>
                <div id="farv.edtaTubeTakenMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td colspan="3" class="sectionTitle">
                <spring:message  code="sample.entry.project.title.dryTube" />
            </td>
        </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.serologyHIVTest" /></td>
                <td>

                    <form:checkbox
                           path="ProjectData.serologyHIVTest"
                           id="farv.serologyHIVTest"
                           onchange="farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.serologyHIVTest'))" />
                    <div id="farv.serologyHIVTestMessage" class="blank" ></div>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.glycemiaTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.glycemiaTest"
                           id="farv.glycemiaTest"
                           onchange="farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.glycemiaTest'))" />
                    <div id="farv.glycemiaTestMessage" class="blank" ></div>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.creatinineTest" /></td>
                <td>
                    <form:checkbox
                            path="ProjectData.creatinineTest"
                            id="farv.creatinineTest"
                            onchange="farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.creatinineTest'))" />
                    <div id="farv.creatinineTest" class="blank" ></div>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.transaminaseTest" /></td>
                <td>
                    <form:checkbox
                            path="ProjectData.transaminaseTest"
                            id="farv.transaminaseTest"
                            onchange="farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.transaminaseTest'))" />
                    <div id="farv.transaminaseTestMessage" class="blank" ></div>
                </td>
            </tr>
            <tr>
                <td></td>
                <td colspan="3" class="sectionTitle">
                    <spring:message  code="sample.entry.project.title.edtaTube" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.nfsTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.nfsTest"
                           id="farv.nfsTest"
                           onchange="farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.nfsTest'))" />
                    <div id="farv.nfsTestMessage" class="blank" ></div>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.cd4cd8Test" /></td>
                <td>
                    <form:checkbox
                                path="ProjectData.cd4cd8Test"
                                id="farv.cd4cd8Test"
                                onchange="farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.cd4cd8Test'))" />
                    <div id="farv.cd4cd8TestMessage" class="blank" ></div>
                </td>
            </tr>
            <tr>
                <td></td>
                <td colspan="3" class="sectionTitle">
                    <spring:message  code="sample.entry.project.title.otherTests" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.viralLoadTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.viralLoadTest"
                           id="farv.viralLoadTest"
                           onchange="farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.viralLoadTest'))" />
                    <div id="farv.viralLoadTestMessage" class="blank" ></div>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.genotypingTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.genotypingTest"
                           id="farv.genotypingTest"
                           onchange="farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.genotypingTest'))" />
                    <div id="farv.genotypingTestMessage" class="blank" ></div>
                </td>
            </tr>
            
            <tr><td colspan="6"><hr/></td></tr>
            <tr id="farv.underInvestigationRow">
                <td class="required"></td>
                <td>
                    <spring:message code="patient.project.underInvestigation" />
                </td>
                <td>
                    <form:select
                    path="observations.underInvestigation" onchange="makeDirty();compareAllObservationHistoryFields(true)"
                    id="farv.underInvestigation">
                    <form:options
                        path="dictionaryLists.YES_NO.list" itemLabel="localizedName"
                        itemalue="id" />
                    </form:select>
                </td>
            </tr>
            <tr id="farv.underInvestigationCommentRow">
                <td class="required"></td>
                <td>
                    <spring:message code="patient.project.underInvestigationComment" />
                </td>
                <td colspan="3">
                    <form:input path="ProjectData.underInvestigationNote" maxlength="1000" size="80"
                        onchange="makeDirty();" id="farv.underInvestigationComment" />
                </td>
            </tr>
    </table>
</div>

<div id="RTN_Id" style="display:none;">
    <h2><spring:message code="sample.entry.project.RTN.title"/></h2>
    <table width="100%">
        <tr>
            <td class="required" width="2%">*</td>
            <td width="28%">
                <spring:message code="sample.entry.project.receivedDate"/>&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td style="width: 70%;">
            <form:input
                    path="receivedDateForDisplay"
                    onkeyup="addDateSlashes(this, event);"
                    onchange="rtn.checkReceivedDate(false)"
                    cssClass="text"
                    id="rtn.receivedDateForDisplay" maxlength="10"/>
                    <div id="rtn.receivedDateForDisplayMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message code="sample.entry.project.receivedTime"/>&nbsp;<spring:message code="sample.military.time.format"/>
            </td>
            <td>
            <form:input
                    path="receivedTimeForDisplay"
                    cssClass="text"
                    onkeyup="filterTimeKeys(this, event);"
                    id="rtn.receivedTimeForDisplay" maxlength="5"                    
                    onblur="rtn.checkReceivedTime(true);" />
                    <div id="rtn.receivedTimeForDisplayMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="sample.entry.project.dateTaken"/>&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
            <form:input
                    path="interviewDate"
                    onkeyup="addDateSlashes(this, event);"
                    onchange="rtn.checkInterviewDate(false)"
                    cssClass="text"
                    id="rtn.interviewDate" maxlength="10"/>
                    <div id="rtn.interviewDateMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message code="sample.entry.project.timeTaken"/>&nbsp;<spring:message code="sample.military.time.format"/>
            </td>
            <td>
            <form:input
                    path="interviewTime"
                    onkeyup="filterTimeKeys(this, event);"
                    cssClass="text"
                    id="rtn.interviewTime" maxlength="5"                    
                    onblur="rtn.checkInterviewTime(true);" />
                    <div id="rtn.interviewTimeMessage" class="blank" />
            </td>
        </tr>       
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
                <form:input
                      path="birthDateForDisplay"
                      cssClass="text"
                      size="20"
                      onkeyup="addDateSlashes(this, event);"
                      onchange="rtn.checkDateOfBirth(true)"
                      id="rtn.dateOfBirth" maxlength="10"/>
                <div id="rtn.dateOfBirthMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message  code="patient.age" />
            </td>
            <td>
                <label for="rtn.age" ><spring:message  code="label.year" /></label>
                <INPUT type='text' name='age' id="rtn.age" size="3"
                    onchange="rtn.checkAge( this, true, 'year' );clearField('rtn.month');"
                    maxlength="2" />
                <label for="rtn.month" ><spring:message  code="label.month" /></label>
                <INPUT type='text' name='month' id="rtn.month" size="3"
                    onchange="rtn.checkAge( this, true, 'month' ); clearField('rtn.age');"
                    maxlength="2" />
                <div id="ageMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message  code="patient.gender" />
            </td>
            <td>
                <form:select
                         path="gender"
                         id="rtn.gender"
                         onchange="rtn.checkGender(true)" >
                <form:options path="genders"
                    itemLabel="localizedName" value="genderType" />
                </form:select>
                <div id="rtn.genderMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <%=StringUtil.getContextualMessageForKey("quick.entry.accession.number")%>
            </td>
            <td>
                <div class="blank"><spring:message code="sample.entry.project.LRTN"/></div>
                <INPUT type="text" name="rtn.labNoForDisplay" id="rtn.labNoForDisplay" size="5" class="text"
                    onchange="handleLabNoChange( this, 'LRTN', false );makeDirty();"
                    maxlength="5" />
                <form:input path="labNo"
                        cssClass="text" style="display:none;"
                        id="rtn.labNo" />
                <div id="rtn.labNoForDisplayMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td colspan="3" class="sectionTitle">
                <spring:message  code="sample.entry.project.title.specimen" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.ARV.dryTubeTaken" /></td>
            <td>
                <form:checkbox
                       path="ProjectData.dryTubeTaken"
                       id="rtn.dryTubeTaken"
                       onchange="rtn.checkSampleItem($('rtn.dryTubeTaken'))" />
                <div id="rtn.dryTubeTakenMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td colspan="3" class="sectionTitle">
                <spring:message  code="sample.entry.project.title.dryTube" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message  code="sample.entry.project.serologyHIVTest" /></td>
            <td>
                <form:checkbox
                       path="ProjectData.serologyHIVTest"
                       id="rtn.serologyHIVTest"
                       onchange="rtn.checkSampleItem($('rtn.dryTubeTaken'), $('rtn.serologyHIVTest'))" />
            </td>
        </tr>
        <tr><td colspan="6"><hr/></td></tr>
        <tr id="rtn.underInvestigationRow">
            <td class="required"></td>
            <td>
                <spring:message code="patient.project.underInvestigation" />
            </td>
            <td>
                <form:select
                path="observations.underInvestigation" onchange="makeDirty();compareAllObservationHistoryFields(true)"
                id="rtn.underInvestigation">
                <form:options
                    path="dictionaryLists.YES_NO.list" itemLabel="localizedName"
                    itemalue="id" />
                </form:select>
            </td>
        </tr>       
        <tr id="rtn.underInvestigationCommentRow">
            <td class="required"></td>
            <td>
                <spring:message code="patient.project.underInvestigationComment" />
            </td>
            <td colspan="3">
                <form:input path="ProjectData.underInvestigationNote" maxlength="1000" size="80"
                    onchange="makeDirty();" id="rtn.underInvestigationComment" />
            </td>
        </tr>
    </table>
</div>

<div id="EID_Id" style="display:none;">
    <h2><spring:message code="sample.entry.project.EID.title"/></h2>
</div>

<div id="VL_Id" style="display:none;">
    <h2><spring:message code="sample.entry.project.VL.title"/></h2>
</div>

<div id="Indeterminate_Id" style="display:none;">
    <h2><spring:message code="sample.entry.project.indeterminate.title"/></h2>
    <table width="100%">
        <tr>
            <td class="required" width="2%">*</td>
            <td width="28%">
                <spring:message code="sample.entry.project.receivedDate"/>&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td width="70%">
            <form:input
                    path="receivedDateForDisplay"
                    onkeyup="addDateSlashes(this, event);"
                    onchange="ind.checkReceivedDate(false);"
                    cssClass="text"
                    id="ind.receivedDateForDisplay" maxlength="10"/>
                    <div id="ind.receivedDateForDisplayMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message code="sample.entry.project.receivedTime"/>&nbsp;<spring:message code="sample.military.time.format"/>
            </td>
            <td>
            <form:input
                    path="receivedTimeForDisplay"
                    onkeyup="filterTimeKeys(this, event);"
                    cssClass="text"
                    id="ind.receivedTimeForDisplay" maxlength="5"                    
                    onblur="ind.checkReceivedTime(true);" />
                    <div id="ind.receivedTimeForDisplayMessage" class="blank" />
            </td>
        </tr>       
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="sample.entry.project.dateTaken"/>&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
            <form:input
                    path="interviewDate"
                    onkeyup="addDateSlashes(this, event);"
                    onchange="ind.checkInterviewDate(false)"
                    cssClass="text"
                    id="ind.interviewDate" maxlength="10"/>
                    <div id="ind.interviewDateMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message code="sample.entry.project.timeTaken"/>&nbsp;<spring:message code="sample.military.time.format"/>
            </td>
            <td>
            <form:input
                    path="interviewTime"
                    onkeyup="filterTimeKeys(this, event);"
                    cssClass="text"
                    id="ind.interviewTime" maxlength="5"                    
                    onblur="ind.checkInterviewTime(true);" />
                    <div id="ind.interviewTimeMessage" class="blank" />
            </td>
        </tr>       
        <tr>
            <td class="required">*</td>
            <td><spring:message code="sample.entry.project.siteName"/></td>
            <td style="width: 40%;">
                <form:select  path="ProjectData.INDsiteName" cssClass="text" id="ind.centerCode"
                        onchange="ind.checkCenterCode(true)" >
                    <form:options path="ProjectData.EIDSites" itemLabel="doubleName" itemalue="id" />
                </form:select>
                <div id="ind.centerCodeMessage" class="blank"/>
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.address"/></td>
            <td>
                <form:input
                        path="ProjectData.address"
                        cssClass="text"
                        id ="ind.address"
                        onchange="ind.checkPatientField('address', true, 'street')" />
                        <div id="ind.addressMessage" class="blank"></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.phoneNumber"/></td>
            <td>
                <form:input
                        path="ProjectData.phoneNumber"
                        cssClass="text"
                        id="ind.phoneNumber"
                        onchange="ind.checkPatientField('phoneNumber')" />
                        <div id="ind.phoneNumberMessage" class="blank"></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.faxNumber"/></td>
            <td>
                <form:input
                        path="ProjectData.faxNumber"
                        cssClass="text"
                        id="ind.faxNumber"
                        onchange="ind.checkPatientField('faxNumber')"/>
                        <div id="ind.faxNumberMessage" class="blank"></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.email"/></td>
            <td>
                <form:input
                        path="ProjectData.email"
                        cssClass="text"
                        id="ind.email"
                        onchange="ind.checkPatientField('email');" />
                        <div id="ind.emailMessage" class="blank"></div>
            </td>
        </tr>
        <tr>
            <td class="required">+</td>
            <td><spring:message code="sample.entry.project.subjectNumber"/></td>
            <td>
                <form:input
                        path="subjectNumber"
                        cssClass="text"
                        id="ind.subjectNumber"
                        maxlength="7"
                        onchange="ind.checkSubjectNumber(true)" />
                <div id="ind.subjectIDMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td class="required">+</td>
            <td><spring:message code="patient.site.subject.number"/></td>
            <td>
                <form:input
                        path="siteSubjectNumber"
                        id="ind.siteSubjectNumber"
                        cssClass="text"
                        onchange="ind.checkSiteSubjectNumber(true)" />
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <%=StringUtil.getContextualMessageForKey("quick.entry.accession.number")%>
            </td>
            <td>
                <div class="blank"><spring:message code="sample.entry.project.LIND"/></div>
                <INPUT type="text" name="ind.labNoForDisplay" id="ind.labNoForDisplay" size="5" class="text"
                    onchange="handleLabNoChange( this, '<spring:message code="sample.entry.project.LIND"/>', false );makeDirty();"
                    maxlength="5" />
                <form:input path="labNo" style="display:none;"
                        cssClass="text"
                        id="ind.labNo" />
                <div id="ind.labNoMessage"  class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message  code="patient.gender" />
            </td>
            <td>
                <form:select
                         path="gender"
                         id="ind.gender"
                         onchange="ind.checkGender(false);" >
                <form:options path="genders"
                    itemLabel="localizedName" value="genderType" />
                </form:select>
                <div id="ind.genderMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
                <form:input
                      path="birthDateForDisplay"
                      cssClass="text"
                      size="20"
                      maxlength="10"
                      id="ind.dateOfBirth"
                      onkeyup="addDateSlashes(this, event);"
                      onchange="ind.checkDateOfBirth(false)"/>
                <div id="ind.dateOfBirthMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message  code="patient.age" />
            </td>
            <td>
                <label for="ind.age" ><spring:message  code="label.year" /></label>
                <INPUT type="text" name="age" id="ind.age" size="3"
                    maxlength="2"
                    onchange="ind.checkAge( this, 'ind.dateOfBirth', 'ind.interviewDate', 'year' ); makeDirty();"/>
                <div id="ageMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td colspan="2" ><h3><spring:message code="sample.entry.project.firstTest"/></h3></td>
        </tr>
        <tr>
        <td></td>
        <td ><spring:message code="sample.entry.project.date"/></td>
        <td>
            <form:input path="observations.indFirstTestDate"
                      cssClass="text"
                      id="ind.indFirstTestDate"
                      maxlength="10"
                      onkeyup="addDateSlashes(this, event);"
                      onchange="compareAllObservationHistoryFields(true, 'ind.');checkValidDate(this);"/>
                      <div id="ind.indFirstTestDateMessage" class="blank" />
        </td>
        </tr>
        <tr>
        <td></td>
        <td><spring:message code="sample.entry.project.testName"/></td>
            <td>
                <form:input path="observations.indFirstTestName"
                          cssClass="text"
                          id="ind.indFirstTestName"
                          onchange="compareAllObservationHistoryFields(true)" />
            </td>
        </tr>
        <tr>
        <td></td>
        <td><spring:message code="sample.entry.project.result"/></td>
        <td>
            <form:input path="observations.indFirstTestResult"
                cssClass="text"
                id="ind.indFirstTestResult"
                onchange="compareAllObservationHistoryFields(true)" />
        </td>
        </tr>


        <tr>
            <td></td>
            <td colspan="2" ><h3><spring:message code="sample.entry.project.secondTest"/></h3></td>
        </tr>
        <tr>
        <td></td>
        <td ><spring:message code="sample.entry.project.date"/></td>
        <td>
            <form:input path="observations.indSecondTestDate"
                      cssClass="text"
                      id="ind.indSecondTestDate"
                      maxlength="10"
                      onkeyup="addDateSlashes(this, event);"
                      onchange="compareAllObservationHistoryFields(true);checkValidDate(this);"/>
                      <div id="ind.indSecondTestDateMessage" class="blank" />
        </td>
        </tr>
        <tr>
        <td></td>
        <td><spring:message code="sample.entry.project.testName"/></td>
            <td>
                <form:input path="observations.indSecondTestName"
                          cssClass="text"
                          id="ind.indSecondTestName"
                          onchange="compareAllObservationHistoryFields(true)" />
            </td>
        </tr>
        <tr>
        <td></td>
        <td><spring:message code="sample.entry.project.result"/></td>
        <td>
            <form:input path="observations.indSecondTestResult"
                cssClass="text"
                id="ind.indSecondTestResult"
                onchange="compareAllObservationHistoryFields(true)" />
        </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.finalResultOfSite"/></td>
            <td>
                <form:input
                    path="observations.indSiteFinalResult"
                    cssClass="text"
                    id="ind.indSiteFinalResult"
                    onchange="compareAllObservationHistoryFields(true)"/>
            </td>
        </tr>
        <tr>
            <td></td>
            <td colspan="2" class="sectionTitle">
                <spring:message  code="sample.entry.project.title.specimen" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.ARV.dryTubeTaken" /></td>
            <td>

                <form:checkbox
                       path="ProjectData.dryTubeTaken"
                       id="ind.dryTubeTaken"
                       onchange="ind.checkSampleItem($('ind.dryTubeTaken'));"/>
            </td>
        </tr>

        <tr>
            <td></td>
            <td colspan="3" class="sectionTitle">
                <spring:message  code="sample.entry.project.title.dryTube" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message  code="sample.entry.project.serologyHIVTest" /></td>
            <td>
                <form:checkbox
                       path="ProjectData.serologyHIVTest"
                       id="ind.serologyHIVTest"
                       onchange="ind.checkSampleItem($('ind.dryTubeTaken'), $('ind.serologyHIVTest'));" />
            </td>
        </tr>
        <tr><td colspan="6"><hr/></td></tr>
        <tr id="ind.underInvestigationRow">
            <td class="required"></td>
            <td>
                <spring:message code="patient.project.underInvestigation" />
            </td>
            <td>
                <form:select
                path="observations.underInvestigation" onchange="makeDirty();compareAllObservationHistoryFields(true)"
                id="ind.underInvestigation">
                <form:options
                    path="dictionaryLists.YES_NO.list" itemLabel="localizedName"
                    itemalue="id" />
                </form:select>
            </td>
        </tr>       
        <tr id="ind.underInvestigationCommentRow">
            <td class="required"></td>
            <td>
                <spring:message code="patient.project.underInvestigationComment" />
            </td>
            <td colspan="3">
                <form:input path="ProjectData.underInvestigationNote" maxlength="1000" size="80"
                    onchange="makeDirty();" id="ind.underInvestigationComment" />
            </td>
        </tr>
    </table>
</div>

<div id="Special_Request_Id" style="display:none;">
    <h2><spring:message code="sample.entry.project.specialRequest.title"/></h2>
    <table width="100%">
        <tr>
            <td class="required" width="2%">*</td>
            <td width="28%">
                <spring:message code="sample.entry.project.receivedDate"/>&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td width="70%">
            <form:input path="receivedDateForDisplay"
                cssClass="text"
                id="spe.receivedDateForDisplay" maxlength="10"
                onkeyup="addDateSlashes(this, event);"
                onchange="spe.checkReceivedDate(false);"/>
                <div id="spe.receivedDateForDisplayMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message code="sample.entry.project.receivedTime"/>&nbsp;<spring:message code="sample.military.time.format"/>
            </td>
            <td>
            <form:input
                    path="receivedTimeForDisplay"
                    onkeyup="filterTimeKeys(this, event);"
                    cssClass="text"
                    id="spe.receivedTimeForDisplay" maxlength="5"                    
                    onblur="spe.checkReceivedTime(true);" />
                    <div id="spe.receivedTimeForDisplayMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="sample.entry.project.dateTaken"/>&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
            <form:input
                    path="interviewDate"
                    cssClass="text"
                    onkeyup="addDateSlashes(this, event);"
                    onchange="spe.checkInterviewDate(false);"
                    id="spe.interviewDate"  maxlength="10"/>
            <div id="spe.interviewDateMessage" class="blank" />
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message code="sample.entry.project.timeTaken"/>&nbsp;<spring:message code="sample.military.time.format"/>
            </td>
            <td>
            <form:input
                    path="interviewTime"
                    onkeyup="filterTimeKeys(this, event);"
                    cssClass="text"
                    id="spe.interviewTime" maxlength="5"                    
                    onblur="spe.checkInterviewTime(true);" />
                    <div id="spe.interviewTimeMessage" class="blank" />
            </td>
        </tr>       
        <tr>
            <td class="required">+</td>
            <td><spring:message code="sample.entry.project.subjectNumber"/></td>
            <td>
                <form:input
                        path="subjectNumber"
                        cssClass="text"
                        id="spe.subjectNumber"
                        maxlength="7"
                        onchange="spe.checkSubjectNumber(true);"  />
                <div id="spe.subjectNumberMessage" class="blank" />
            </td>
        </tr>
        <tr>
            <td class="required">+</td>
            <td><spring:message code="patient.site.subject.number"/></td>
            <td>
                <form:input
                        path="siteSubjectNumber"
                        id="spe.siteSubjectNumber"
                        cssClass="text"
                        onchange="spe.checkSiteSubjectNumber(true)" />
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message code="patient.birthDate" />&nbsp;<%=DateUtil.getDateUserPrompt()%>
            </td>
            <td>
                <form:input
                      path="birthDateForDisplay"
                      cssClass="text"
                      size="20"
                      maxlength="10"
                      onkeyup="addDateSlashes(this, event);"
                      onchange="spe.checkDateOfBirth(false)"
                      id="spe.dateOfBirth" />
                <div id="spe.dateOfBirthMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td>
                <spring:message  code="patient.age" />
            </td>
            <td>
                <label for="spe.age" ><spring:message  code="label.year" /></label>
                <INPUT type="text" name="age" id="spe.age" size="3"
                    onchange="spe.checkAge( this, true, 'year'); updatePatientEditStatus(); makeDirty();"
                    maxlength="3" />
                <div id="ageMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <spring:message  code="patient.gender" />
            </td>
            <td>
                <form:select
                         path="gender"
                         id="spe.gender"
                         onchange="spe.checkGender(false);" >
                    <form:options path="genders"
                        itemLabel="localizedName" value="genderType" />
                </form:select>
                <div id="spe.genderMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td class="required">*</td>
            <td>
                <%=StringUtil.getContextualMessageForKey("quick.entry.accession.number")%>
            </td>
            <td>
                <div class="blank"><spring:message code="sample.entry.project.LSPE"/></div>
                <INPUT type="text" name="spe.labNoForDisplay" id="spe.labNoForDisplay" size="5" class="text"
                    onchange="handleLabNoChange( this, '<spring:message code="sample.entry.project.LSPE"/>', 'false' );makeDirty();"
                    maxlength="5" />
                <form:input path="labNo"
                        cssClass="text" style="display:none;"
                        id="spe.labNo" />
                <div id="spe.labNoMessage" class="blank" ></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.specialRequest.reason"/></td>
            <td>
                <form:select
                             path="observations.reasonForRequest"
                             id="spe.reasonForRequest"
                             onchange="compareAllObservationHistoryFields(true)">
                    <form:options
                        path="ProjectData.requestReasons"
                        itemLabel="localizedName"
                        itemalue="id" />
                </form:select>
            </td>
        </tr>
        <tr>
            <td ></td>
            <td colspan="2" class="sectionTitle">
                <spring:message  code="sample.entry.project.title.specimen" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.ARV.dryTubeTaken" /></td>
            <td>
                <form:checkbox
                        path="ProjectData.dryTubeTaken"
                        id="spe.dryTubeTaken"
                        onchange="spe.checkSampleItem($('spe.dryTubeTaken'));"/>
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.ARV.edtaTubeTaken" /></td>
            <td>
                <form:checkbox
                        path="ProjectData.edtaTubeTaken"
                        id="spe.edtaTubeTaken"
                        onchange="spe.checkSampleItem($('spe.edtaTubeTaken'));"/>
            </td>
        </tr>
        <tr>
            <td></td>
            <td><spring:message code="sample.entry.project.title.dryBloodSpot" /></td>
            <td>
                <form:checkbox
                        path="ProjectData.dbsTaken"
                        id="spe.dbsTaken"
                        onchange="spe.checkSampleItem($('spe.dbsTaken'))" />
            </td>
        </tr>
        <tr>
            <td></td>
            <td colspan="2" class="sectionTitle">
                <spring:message  code="sample.entry.project.title.dryTube" />
            </td>
        </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.murexTest" /></td>
                <td>
                    <form:checkbox
                            path="ProjectData.murexTest"
                            id="spe.murexTest"
                            onchange="spe.checkSampleItem($('spe.dryTubeTaken'), $('spe.murexTest'))"/>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.integralTest" /></td>
                <td>
                    <form:checkbox
                            path="ProjectData.integralTest"
                            id="spe.integralTest"
                            onchange="spe.checkSampleItem($('spe.dryTubeTaken'), $('spe.integralTest'))"/>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.vironostikaTest" /></td>
                <td>
                    <form:checkbox
                            path="ProjectData.vironostikaTest"
                            id="spe.vironostikaTest"
                            onchange="spe.checkSampleItem($('spe.dryTubeTaken'), $('spe.vironostikaTest'))"/>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.innoliaTest" /></td>
                <td>
                    <form:checkbox
                            path="ProjectData.innoliaTest"
                            id="spe.innoliaTest"
                            onchange="spe.checkSampleItem($('spe.dryTubeTaken'), $('spe.innoliaTest'))"/>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.glycemiaTest" /></td>
                <td>
                    <form:checkbox
                                path="ProjectData.glycemiaTest"
                                id="spe.glycemiaTest"
                                onchange="spe.checkSampleItem($('spe.dryTubeTaken'), $('spe.glycemiaTest'))"/>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.creatinineTest" /></td>
                <td>
                    <form:checkbox
                                path="ProjectData.creatinineTest"
                                id="spe.creatinineTest"
                                onchange="spe.checkSampleItem($('spe.dryTubeTaken'), $('spe.creatinineTest'))"/>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.transaminaseTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.transaminaseTest"
                           id="spe.transaminaseTest"
                           onchange="spe.checkSampleItem($('spe.dryTubeTaken'), $('spe.transaminaseTest'))" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.transaminaseALTLTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.transaminaseALTLTest"
                           id="spe.transaminaseALTLTest"
                           onchange="spe.checkSampleItem($('spe.dryTubeTaken'), $('spe.transaminaseALTLTest'))" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.transaminaseASTLTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.transaminaseASTLTest"
                           id="spe.transaminaseASTLTest"
                           onchange="spe.checkSampleItem($('spe.dryTubeTaken'), $('spe.transaminaseASTLTest'))" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td colspan="2" class="sectionTitle">
                    <spring:message  code="sample.entry.project.title.edtaTube"/>
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.nfsTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.nfsTest"
                           id="spe.nfsTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.nfsTest'))" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.gbTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.gbTest"
                           id="spe.gbTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.gbTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.lymphTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.lymphTest"
                           id="spe.lymphTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.lymphTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.monoTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.monoTest"
                           id="spe.monoTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.monoTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.eoTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.eoTest"
                           id="spe.eoTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.eoTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.basoTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.basoTest"
                           id="spe.basoTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.basoTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.grTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.grTest"
                           id="spe.grTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.grTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.hbTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.hbTest"
                           id="spe.hbTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.hbTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.hctTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.hctTest"
                           id="spe.hctTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.hctTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.vgmTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.vgmTest"
                           id="spe.vgmTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.vgmTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.tcmhTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.tcmhTest"
                           id="spe.tcmhTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.tcmhTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ccmhTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.ccmhTest"
                           id="spe.ccmhTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.ccmhTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.plqTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.plqTest"
                           id="spe.plqTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.plqTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.cd4cd8Test" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.cd4cd8Test"
                           id="spe.cd4cd8Test"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.cd4cd8Test'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.cd3CountTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.cd3CountTest"
                           id="spe.cd3CountTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.cd3CountTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.cd4CountTest" /></td>
                <td>
                    <form:checkbox
                           path="ProjectData.cd4CountTest"
                           id="spe.cd4CountTest"
                           onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.cd4CountTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td colspan="2" class="sectionTitle">
                    <spring:message  code="sample.entry.project.title.otherTests" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.dnaPCR" /></td>
                <td>
                    <form:checkbox
                       path="ProjectData.dnaPCR"
                       id="spe.dnaPCR"
                       onchange="spe.checkSampleItem($('spe.dbsTaken'), $('spe.dnaPCR'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.viralLoadTest" /></td>
                <td>
                    <form:checkbox
                       path="ProjectData.viralLoadTest"
                       id="spe.viralLoadTest"
                       onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.viralLoadTest'));" />
                </td>
            </tr>
            <tr>
                <td></td>
                <td><spring:message code="sample.entry.project.ARV.genotypingTest" /></td>
                <td>
                    <form:checkbox
                       path="ProjectData.genotypingTest"
                       id="spe.genotypingTest"
                       onchange="spe.checkSampleItem($('spe.edtaTubeTaken'), $('spe.genotypingTest'));" />
                </td>
            </tr>
            <tr><td colspan="6"><hr/></td></tr>
            <tr id="spe.underInvestigationRow">
                <td class="required"></td>
                <td>
                    <spring:message code="patient.project.underInvestigation" />
                </td>
                <td>
                    <form:select
                    path="observations.underInvestigation" onchange="makeDirty();compareAllObservationHistoryFields(true)"
                    id="spe.underInvestigation">
                    <form:options
                        path="dictionaryLists.YES_NO.list" itemLabel="localizedName"
                        itemalue="id" />
                    </form:select>
                </td>
            </tr>
            <tr id="spe.underInvestigationCommentRow">
                <td class="required"></td>
                <td>
                    <spring:message code="patient.project.underInvestigationComment" />
                </td>
                <td colspan="3">
                    <form:input path="ProjectData.underInvestigationNote" maxlength="1000" size="80"
                        onchange="makeDirty();" id="spe.underInvestigationComment" />
                </td>
            </tr>
    </table>
</div>
</div>

<script type="text/javascript">
    // On load using the built in feature of OpenElis pages onLoad
/**
 * A list of answers that equate to yes in certain lists when comparing (cross check or 2nd entry for a match).
 */
yesesInDiseases = [
     <%= us.mn.state.health.lims.dictionary.ObservationHistoryList.YES_NO.getList().get(0).getId() %>,
     <%= us.mn.state.health.lims.dictionary.ObservationHistoryList.YES_NO_UNKNOWN.getList().get(0).getId() %>
     ];


function ArvInitialProjectChecker() {
    this.idPre = "iarv.";

    this.checkAllSampleItemFields = function () {
        this.checkSampleItem($("iarv.dryTubeTaken"));
        this.checkSampleItem($("iarv.edtaTubeTaken"));
        this.checkSampleItem($('iarv.dryTubeTaken'), $('iarv.serologyHIVTest'));
        this.checkSampleItem($('iarv.dryTubeTaken'), $('iarv.glycemiaTest'));
        this.checkSampleItem($('iarv.dryTubeTaken'), $('iarv.creatinineTest'));
        this.checkSampleItem($('iarv.dryTubeTaken'), $('iarv.transaminaseTest'));
        this.checkSampleItem($('iarv.edtaTubeTaken'), $('iarv.nfsTest'));
        this.checkSampleItem($('iarv.edtaTubeTaken'), $('iarv.cd4cd8Test'));
        this.checkSampleItem($('iarv.edtaTubeTaken'), $('iarv.viralLoadTest'));
        this.checkSampleItem($('iarv.edtaTubeTaken'), $('iarv.genotypingTest'));
    }
}
ArvInitialProjectChecker.prototype = new BaseProjectChecker();
iarv = new ArvInitialProjectChecker();

function ArvFollowupProjectChecker() {

    this.idPre = "farv.";

    this.checkAllSampleItemFields = function() {
        farv.checkSampleItem($('farv.dryTubeTaken'));
        farv.checkSampleItem($('farv.edtaTubeTaken'));
        farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.serologyHIVTest'));
        farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.glycemiaTest'));
        farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.creatinineTest'));
        farv.checkSampleItem($('farv.dryTubeTaken'), $('farv.transaminaseTest'));
        farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.nfsTest'));
        farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.cd4cd8Test'));
        farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.viralLoadTest'));
        farv.checkSampleItem($('farv.edtaTubeTaken'), $('farv.genotypingTest'));
    }
}

ArvFollowupProjectChecker.prototype = new BaseProjectChecker();
/// the object which knows about Followup ARV questions and which fields to show etc.
farv = new ArvFollowupProjectChecker();

function RtnProjectChecker() {
    this.idPre = "rtn.";

    this.checkAllSampleFields = function (blanksAllowed) {
        // this.checkCenterName(blanksAllowed);
        // this.checkCenterCode(blanksAllowed);
        this.checkInterviewDate(blanksAllowed);
        this.checkReceivedDate(blanksAllowed);
        //var receivedTimeField = $(this.idPre + "receivedTimeForDisplay");
        //compareSampleField( receivedTimeField.id, false, blanksAllowed);
        //var interviewTimeField = $(this.idPre + "interviewTime");
        //compareSampleField( interviewTimeField.id, false, blanksAllowed, "collectionTimeForDisplay");
        this.checkInterviewTime(true);
        this.checkReceivedTime(true);
    }

    this.checkAllSampleItemFields = function () {
        this.checkSampleItem($("rtn.dryTubeTaken"));
        this.checkSampleItem($('rtn.dryTubeTaken'), $('rtn.serologyHIVTest'));
        // TODO PAHill list ALL sampleItem and Test fields
    }
}

RtnProjectChecker.prototype = new BaseProjectChecker();
rtn = new RtnProjectChecker();

function IndProjectChecker() {
    this.idPre = "ind.";

    this.checkAllSampleFields = function (blanksAllowed) {
        // this.checkCenterName(blanksAllowed);
        this.checkCenterCode(blanksAllowed);
        this.checkInterviewDate(blanksAllowed);
        this.checkReceivedDate(blanksAllowed);
        this.checkInterviewTime(true);
        this.checkReceivedTime(true);
    }

    this.checkAllSampleItemFields = function () {
        ind.checkSampleItem($('ind.dryTubeTaken'));
        ind.checkSampleItem($('ind.dryTubeTaken'), $('ind.serologyHIVTest'));
    }

    this.checkAllSubjectFields = function (blanksAllowed, validateSubjectNumber) {
        this.checkAllSubjectFieldsBasic(blanksAllowed, validateSubjectNumber);
        this.checkPatientField('address', blanksAllowed, 'street');
        this.checkPatientField('phoneNumber', blanksAllowed);
        this.checkPatientField('faxNumber', blanksAllowed);
        this.checkPatientField('email', blanksAllowed);
    }
}
IndProjectChecker.prototype = new BaseProjectChecker();
ind = new IndProjectChecker();

function SpeProjectChecker() {
    this.idPre = "spe."

    this.checkAllSampleFields = function (blanksAllowed) {
        // this.checkCenterName(blanksAllowed);
        // this.checkCenterCode(blanksAllowed);
        this.checkInterviewDate(blanksAllowed);
        this.checkReceivedDate(blanksAllowed);
        this.checkInterviewTime(true);
        this.checkReceivedTime(true);
    }

    this.checkAllSampleItemFields = function () {
    }
}
SpeProjectChecker.prototype = new BaseProjectChecker();
spe = new SpeProjectChecker();

function pageOnLoad(){
    initializeStudySelection();
    studies.initializeProjectChecker();
    projectChecker == null || projectChecker.refresh(); 
}
</script>