Select
  
hou.Name as Company,
eer.EXPENSE_REPORT_NUM as ExpReportNumber,
eer.PURPOSE as ExpPurpose,
eer.PAYMENT_METHOD_CODE as ExpMethodCode,
statuscodes.DISPLAYED_FIELD  as ExpStatus,
eer.EXPENSE_REPORT_TOTAL as ExpReportTotal,
eer.REIMBURSEMENT_CURRENCY_CODE as ExpCurrencyCode,
eer.EXPENSE_REPORT_DATE as ExpReportDate,
eer.REPORT_SUBMIT_DATE as ExpSubmitDate,
eer.FINAL_APPROVAL_DATE as ExpFinalApprovalDate,
eer.CASH_EXPENSE_PAID_DATE as ExpPaidDate,
eer.CREATION_DATE as ExpCreationDate,
perexp.Display_Name as ExpensedPerson,

expline.RECEIPT_AMOUNT LineAmount,
expline.REIMBURSABLE_AMOUNT LineAmountDoviz,
expline.RECEIPT_CURRENCY_CODE LineCurrency,
expline.EXCHANGE_RATE LineExchangeRate,
expline.TAX_CLASSIFICATION_CODE TaxPer,
expline.MERCHANT_DOCUMENT_NUMBER ReceiptNo,
expline.START_DATE ReceiptDate,

TO_CHAR(expline.START_DATE, 'YYYY, MONTH') as ReceiptMonth,

gcc.segment2 Account,
accountexp.Description AccountDescription,
prj.SEGMENT1 Project,
prje.ELEMENT_NUMBER Task,
expdist.PJC_Expenditure_Item_Date ExpItemDate,

Initcap(projcodemainp.Meaning) MainProject,
Initcap(projcodeloca.Meaning) ProjectLocation,
Initcap(projcodecont.Meaning) ProjectContentType,
Initcap(projel.Text_Attr01) Season,

expline.ATTRIBUTE_CHAR1 CostCat,
expline.ATTRIBUTE_CHAR6 MemberType,
expline.ATTRIBUTE_CHAR7 Member,
expline.ATTRIBUTE_CHAR8 LocationX,
expline.ATTRIBUTE_CHAR9 Route,
expline.ATTRIBUTE_CHAR13 ProcessType,

costcat.Description CostCatDesc,  
membertype.Description MemberTypeExpd, 
memberexp.Description MemberExpd,
placeexp.Description  PlaceExpd,
parkourexp.Description ParkourExpd,
processexp.Description ProcessExpd



From EXM_EXPENSE_REPORTS eer
Inner Join EXM_EXPENSES expline 
    Left Join FND_VS_VALUES_VL costcat ON costcat.Value = expline.ATTRIBUTE_CHAR1 and costcat.ATTRIBUTE_CATEGORY like 'ACM_Business_Function_VS' 
    Left Join FND_VS_VALUES_VL membertype ON membertype.Value = expline.ATTRIBUTE_CHAR6 and membertype.ATTRIBUTE_CATEGORY like 'ACM_Member_Type_VS' 
    Left Join FND_VS_VALUES_VL memberexp ON memberexp.Value = expline.ATTRIBUTE_CHAR7 and memberexp.INDEPENDENT_VALUE = expline.ATTRIBUTE_CHAR6 and memberexp.ATTRIBUTE_CATEGORY like 'ACM_Member_VS' 
    Left Join FND_VS_VALUES_VL placeexp ON placeexp.Value = expline.ATTRIBUTE_CHAR8 and placeexp.ATTRIBUTE_CATEGORY like 'ACM_Place_VS' 
    Left Join FND_VS_VALUES_VL parkourexp ON parkourexp.Value = expline.ATTRIBUTE_CHAR9 and parkourexp.ATTRIBUTE_CATEGORY like 'ACM_Parkour_VS' 
    Left Join FND_VS_VALUES_VL processexp ON processexp.Value = expline.ATTRIBUTE_CHAR13 and processexp.ATTRIBUTE_CATEGORY like 'ACM_ProcessType_VS' 
    Inner Join EXM_EXPENSE_DISTS expdist 
        Inner Join gl_code_combinations gcc
            Inner Join FND_VS_VALUES_VL accountexp 
            ON gcc.segment2 = accountexp.VALUE  and accountexp.ATTRIBUTE_CATEGORY like 'ACM_Account' 
        ON gcc.code_combination_id= expdist.code_combination_id and gcc.enabled_flag='Y'
        Left Join PJF_PROJECTS_ALL_VL prj
            Inner Join PJF_PROJ_ELEMENTS_VL projel
                Left Join PJT_COLUMN_LKP_VALUES_VL projcodemainp ON projel.TASK_CODE01_ID = projcodemainp.Code_value_Id and projcodemainp.Column_Map_Id = '300000011071779'
                Left Join PJT_COLUMN_LKP_VALUES_VL projcodeloca ON projel.TASK_CODE02_ID = projcodeloca.Code_value_Id and projcodeloca.Column_Map_Id = '300000020011425'
                Left Join PJT_COLUMN_LKP_VALUES_VL projcodecont ON projel.TASK_CODE03_ID = projcodecont.Code_value_Id and projcodecont.Column_Map_Id = '300000028309790'
            On projel.Project_Id = prj.Project_Id and projel.OBJECT_TYPE = 'PJF_STRUCTURES'
        ON expdist.PJC_PROJECT_ID=prj.PROJECT_ID
        Left Join PJF_PROJ_ELEMENTS_vl prje
        ON expdist.PJC_TASK_ID = prj.PROJ_ELEMENT_ID
    ON expdist.expense_id= expline.expense_id
ON eer.expense_report_id = expline.expense_report_id
Inner Join EXM_LOOKUP_VALUES statuscodes ON eer.EXPENSE_STATUS_CODE = statuscodes.LOOKUP_CODE and statuscodes.LOOKUP_TYPE = 'EXM_REPORT_STATUS' 
Inner Join HR_ORGANIZATION_UNITS_F_TL hou  ON eer.Org_Id = hou.Organization_Id and hou.Language = 'US'
Inner Join PER_PERSON_NAMES_F_V perexp ON perexp.PERSON_ID = eer.PERSON_ID and perexp.Name_Type = 'GLOBAL' and sysdate between perexp.Effective_Start_Date and perexp.Effective_End_Date 
Where  statuscodes.DISPLAYED_FIELD IN ('Paid', 'Partially paid', 'Ready for payment', 'Pending expense auditor approval', 'Ready for payment processing')
and (hou.Name like '%Exxen%' or Initcap(projcodemainp.Meaning) = 'Exxen' )

Order By  eer.CREATION_DATE Desc