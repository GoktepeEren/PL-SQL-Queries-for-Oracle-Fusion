Select
  eca.CASH_ADVANCE_ID,
  eca.ASSIGNMENT_ID,
  eca.ORG_ID,
  eca.PERSON_ID,
  per.DISPLAY_NAME as Person,
  eca.CASH_ADVANCE_NUMBER,
  eca.STATUS_CODE,
  eca.CASH_ADVANCE_TYPE,
  eca.PURPOSE,
  eca.AMOUNT,
  eca.CURRENCY_CODE,
  eca.PAYMENT_AMOUNT,
  eca.PAYMENT_CURRENCY_CODE,
  eca.CREATED_BY,
  eca.CREATION_DATE,
  eca.SUBMITTED_DATE,
  eca.SETTLEMENT_DATE,
  ecaa.EXPENSE_REPORT_ID,
  ecaa.AMOUNT as CapAmount,
  ecaa.CURRENCY_CODE as CapCurrencyCode,
  eer.PERSON_ID as ExpPersonId,
  perexp.DISPLAY_NAME as ExpPerson,
  eer.PAYMENT_METHOD_CODE as ExpMethodCode,
  eer.EXPENSE_REPORT_DATE as ExpReportDate,
  eer.EXPENSE_REPORT_TOTAL as ExpReportTotal,
  eer.EXPENSE_REPORT_NUM as ExpReportNumber,
  eer.EXPENSE_STATUS_CODE as ExpStatus,
  eer.PURPOSE as ExpPurpose,
  eer.REIMBURSEMENT_CURRENCY_CODE as ExpCurrencyCode,
  eer.REPORT_SUBMIT_DATE as ExpSubmitDate,
  eer.FINAL_APPROVAL_DATE as ExpFinalApprovalDate,
  eer.CASH_EXPENSE_PAID_DATE as ExpPaidDate,
  eer.CREATION_DATE as ExpCreationDate,
  hou.Name as OrganizationName
From
EXM_CASH_ADVANCES eca
Left Join EXM_CASH_ADV_APPLICATIONS ecaa ON eca.CASH_ADVANCE_ID = ecaa.CASH_ADVANCE_ID
Left Join EXM_EXPENSE_REPORTS eer ON ecaa.EXPENSE_REPORT_ID = eer.EXPENSE_REPORT_ID 
Left Join HR_OPERATING_UNITS hou ON eca.Org_Id = hou.Organization_Id
Left  Join PER_PERSON_NAMES_F_V per ON per.PERSON_ID = eca.PERSON_ID
Left  Join PER_PERSON_NAMES_F_V perexp ON perexp.PERSON_ID = eer.PERSON_ID
Where 
hou.Name IN (:OrgNameX) And per.DISPLAY_NAME IN (:PersonName)
And eca.CASH_ADVANCE_NUMBER like UPPER('%'||:CashNumber||'%')  
And eca.STATUS_CODE IN (:CashStatus)
Order By eca.CASH_ADVANCE_NUMBER DESC