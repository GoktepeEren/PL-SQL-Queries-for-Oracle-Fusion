Select
  
  eer.EXPENSE_REPORT_NUM as ExpReportNumber,
  eer.PURPOSE as ExpPurpose,
  eer.PAYMENT_METHOD_CODE as ExpMethodCode,
  eer.EXPENSE_STATUS_CODE as ExpStatus,
  eer.EXPENSE_REPORT_TOTAL as ExpReportTotal,
  eer.REIMBURSEMENT_CURRENCY_CODE as ExpCurrencyCode,
  eer.EXPENSE_REPORT_DATE as ExpReportDate,
  eer.REPORT_SUBMIT_DATE as ExpSubmitDate,
  eer.FINAL_APPROVAL_DATE as ExpFinalApprovalDate,
  eer.CASH_EXPENSE_PAID_DATE as ExpPaidDate,
  eer.CREATION_DATE as ExpCreationDate,
  perexp.Display_Name as ExpensedPerson,
  eca.CASH_ADVANCE_ID,
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
  per.DISPLAY_NAME as Person

From EXM_EXPENSE_REPORTS eer 
    Left Join EXM_CASH_ADV_APPLICATIONS ecaa
        Inner Join EXM_CASH_ADVANCES eca    
            Inner Join PER_PERSON_NAMES_F_V per 
            ON per.PERSON_ID = eca.PERSON_ID and per.Name_Type = 'GLOBAL' and sysdate between per.Effective_Start_Date and per.Effective_End_Date 
        ON eca.CASH_ADVANCE_ID = ecaa.CASH_ADVANCE_ID
    ON ecaa.EXPENSE_REPORT_ID = eer.EXPENSE_REPORT_ID 
Inner Join HR_OPERATING_UNITS hou ON eer.Org_Id = hou.Organization_Id
Inner Join PER_PERSON_NAMES_F_V perexp ON perexp.PERSON_ID = eer.PERSON_ID and perexp.Name_Type = 'GLOBAL' and sysdate between perexp.Effective_Start_Date and perexp.Effective_End_Date 

Where 

hou.Name IN (:OrgNameX) 
And perexp.DISPLAY_NAME IN (:PersonName)
And eer.EXPENSE_REPORT_NUM like UPPER('%'||:ExpReportNumber||'%')  
And eer.EXPENSE_STATUS_CODE IN (:ExpStatus)

Order By  eer.CREATION_DATE Desc
  