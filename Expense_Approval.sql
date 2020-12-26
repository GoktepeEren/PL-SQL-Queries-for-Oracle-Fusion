select 
org.Name as CompanyName,
eer.EXPENSE_REPORT_Id,
EER.EXPENSE_REPORT_NUM EXPENSE_REPORT_NUM,
eer.PURPOSE,
eer.ATTRIBUTE_CHAR7 ExpenseTypeDFF,
statuscodes.DISPLAYED_FIELD Status,
EER.EXPENSE_REPORT_TOTAL,
EER.REIMBURSEMENT_CURRENCY_CODE HEADERCURRENCY,
EER.EXPENSE_REPORT_DATE,
EER.REPORT_SUBMIT_DATE,
eer.CREATION_DATE,
eer.CREATED_BY,
PersonNameDPEO.DISPLAY_NAME,
wf.ASSIGNEESDISPLAYNAME AssignedPerson

from
exm_expense_reports eer,
PER_PERSON_NAMES_F_V PersonNameDPEO,
EXM_LOOKUP_VALUES statuscodes,
HR_ORGANIZATION_UNITS_F_TL org,
fa_fusion_soainfra.wftask wf 

where 1=1
and eer.PERSON_ID = PersonNameDPEO.PERSON_ID
AND PersonNameDPEO.Name_Type = 'GLOBAL' and Trunc(Sysdate) between PersonNameDPEO.EFFECTIVE_START_DATE and PersonNameDPEO.EFFECTIVE_End_DATE
and eer.EXPENSE_STATUS_CODE = statuscodes.LOOKUP_CODE
and statuscodes.LOOKUP_TYPE = 'EXM_REPORT_STATUS' 
and eer.ORG_ID = org.ORGANIZATION_ID and org.Language = 'US'
and statuscodes.DISPLAYED_FIELD = 'Pending manager approval'

AND ( wf.state = 'ASSIGNED' OR wf.state = 'INFO_REQUESTED' )
AND wf.assignees IS NOT NULL
AND wf.workflowpattern NOT IN ( 'AGGREGATION', 'FYI' )
And wf.TASKDEFINITIONNAME = 'FinExmWorkflowExpenseApproval'
and wf.IDENTIFICATIONKEY = eer.EXPENSE_REPORT_Id

and org.Name IN (:CompanyName)
and EER.EXPENSE_REPORT_NUM like '%' || (:ExpReportNumber) || '%'

order by eer.CREATION_DATE desc