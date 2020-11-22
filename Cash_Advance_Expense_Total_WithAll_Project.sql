Select
    hou.Name as OrganizationName,
    eca.CASH_ADVANCE_ID,
    eca.ASSIGNMENT_ID,
    eca.ORG_ID,
    eca.PERSON_ID,
    per.DISPLAY_NAME as Person,
    eca.CASH_ADVANCE_NUMBER,
    eca.STATUS_CODE,
    statutbl.LOOKUP_TYPE,
    statutbl.DISPLAYED_FIELD,
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
    TO_CHAR(eca.SETTLEMENT_DATE, 'YYYY, MONTH') as SettlementMonth,
    eca.ATTRIBUTE_CHAR13 ProcessType,
    eca.ATTRIBUTE_NUMBER1 TaskId,
    eca.ATTRIBUTE_NUMBER5 ProjectId,
    prj.SEGMENT1 Project,
    prje.ELEMENT_NUMBER Task,

    Initcap(projcodemainp.Meaning) MainProject,
    Initcap(projcodeloca.Meaning) ProjectLocation,
    Initcap(projcodecont.Meaning) ProjectContentType,
    Initcap(projel.Text_Attr01) Season,
    processexp.Description ProcessExpd,

    (Select
        NVL(Sum(ecaanew.AMOUNT),0)
    From EXM_CASH_ADVANCES ecanew
    Left Join EXM_CASH_ADV_APPLICATIONS ecaanew 
        Left Join EXM_EXPENSE_REPORTS eernew 
        ON ecaanew.EXPENSE_REPORT_ID = eernew.EXPENSE_REPORT_ID 
    ON ecanew.CASH_ADVANCE_ID = ecaanew.CASH_ADVANCE_ID
    Where ecanew.CASH_ADVANCE_ID = eca.CASH_ADVANCE_ID 
    Group By ecanew.CASH_ADVANCE_ID) TotalExpenses,

    
    (Case 
    When (Select
        NVL(Sum(ecaanew.AMOUNT),0)
    From EXM_CASH_ADVANCES ecanew
    Left Join EXM_CASH_ADV_APPLICATIONS ecaanew 
        Left Join EXM_EXPENSE_REPORTS eernew 
        ON ecaanew.EXPENSE_REPORT_ID = eernew.EXPENSE_REPORT_ID 
    ON ecanew.CASH_ADVANCE_ID = ecaanew.CASH_ADVANCE_ID
    Where ecanew.CASH_ADVANCE_ID = eca.CASH_ADVANCE_ID 
    Group By ecanew.CASH_ADVANCE_ID) = 0 Then eca.AMOUNT
    Else
    (Select
        NVL(Sum(ecaanew.AMOUNT),0)
    From EXM_CASH_ADVANCES ecanew
    Left Join EXM_CASH_ADV_APPLICATIONS ecaanew 
        Left Join EXM_EXPENSE_REPORTS eernew 
        ON ecaanew.EXPENSE_REPORT_ID = eernew.EXPENSE_REPORT_ID 
    ON ecanew.CASH_ADVANCE_ID = ecaanew.CASH_ADVANCE_ID
    Where ecanew.CASH_ADVANCE_ID = eca.CASH_ADVANCE_ID 
    Group By ecanew.CASH_ADVANCE_ID) End) as BalanceExpenses
    

    -- eer.EXPENSE_REPORT_NUM as ExpReportNumber,
    -- eer.EXPENSE_REPORT_TOTAL as ExpReportTotal,
    -- eer.EXPENSE_STATUS_CODE as ExpStatus,
    -- eer.REIMBURSEMENT_CURRENCY_CODE as ExpCurrencyCode

From
EXM_CASH_ADVANCES eca
-- Left Join EXM_CASH_ADV_APPLICATIONS ecaa 
--     Left Join EXM_EXPENSE_REPORTS eer 
--     ON ecaa.EXPENSE_REPORT_ID = eer.EXPENSE_REPORT_ID 
-- ON eca.CASH_ADVANCE_ID = ecaa.CASH_ADVANCE_ID
Left Join HR_OPERATING_UNITS hou ON eca.Org_Id = hou.Organization_Id
Left Join PER_PERSON_NAMES_F_V per ON per.PERSON_ID = eca.PERSON_ID and per.Name_Type = 'GLOBAL' and sysdate between per.Effective_Start_Date and per.Effective_End_Date 
Left Join PJF_PROJECTS_ALL_VL prj
    Inner Join PJF_PROJ_ELEMENTS_VL projel
        Left Join PJT_COLUMN_LKP_VALUES_VL projcodemainp ON projel.TASK_CODE01_ID = projcodemainp.Code_value_Id and projcodemainp.Column_Map_Id = '300000011071779'
        Left Join PJT_COLUMN_LKP_VALUES_VL projcodeloca ON projel.TASK_CODE02_ID = projcodeloca.Code_value_Id and projcodeloca.Column_Map_Id = '300000020011425'
        Left Join PJT_COLUMN_LKP_VALUES_VL projcodecont ON projel.TASK_CODE03_ID = projcodecont.Code_value_Id and projcodecont.Column_Map_Id = '300000028309790'
    On projel.Project_Id = prj.Project_Id and projel.OBJECT_TYPE = 'PJF_STRUCTURES'
ON eca.ATTRIBUTE_NUMBER5 = prj.PROJECT_ID
Left Join PJF_PROJ_ELEMENTS_vl prje
ON eca.ATTRIBUTE_NUMBER1 = prje.PROJ_ELEMENT_ID
Left Join FND_VS_VALUES_VL processexp 
ON processexp.Value = eca.ATTRIBUTE_CHAR13 and processexp.ATTRIBUTE_CATEGORY like 'ACM_ProcessType_VS' 
Inner Join EXM_LOOKUP_VALUES statutbl
ON statutbl.LOOKUP_CODE = eca.STATUS_CODE and statutbl.LOOKUP_TYPE = 'EXM_CASH_ADVANCE_STATUS'

Where  statutbl.DISPLAYED_FIELD IN ('Applied', 'Overdue', 'Closed', 'Paid')
Order By eca.CREATION_DATE DESC