Select

ProjDetail.TypeRep,
ProjDetail.CreationYear,
ProjDetail.CreationMonthText,
ProjDetail.CreationMonth,
ProjDetail.Company,
ProjDetail.OrderNumber,
ProjDetail.OrderDocumentStatus,

ProjDetail.SuppName,

ProjDetail.LineNumber,
ProjDetail.LineType,
ProjDetail.LineDesc,

ProjDetail.LineUnitCode,
ProjDetail.LineQuantity,
ProjDetail.LineUnitPrice,

ProjDetail.AccountDescTotal,
ProjDetail.Category_Name,

ProjDetail.ProjectName,
ProjDetail.ProjectTaskName,
ProjDetail.CURRENCY_CODE,
ProjDetail.LedgerCurrency,
ProjDetail.Rate,
ProjDetail.AmountOrderCurrency,
ProjDetail.AmountLedgerCurrency,
ProjDetail.AmountUSD,

ProjDetail.Buyer,
ProjDetail.ExpenditureItemDate,
ProjDetail.OrderCreationDate,
ProjDetail.OrderSubmitDate,
ProjDetail.OrderApprovedDate,

ProjDetail.CostCatDesc,
ProjDetail.MemberTypeExpd,
ProjDetail.MemberExpd,
ProjDetail.PlaceExpd,
ProjDetail.ProcessExpd

From 
(
    -- Order
    (
        SELECT
        --1
        'Order' as TypeRep,

        --2
        EXTRACT(YEAR FROM pod.PJC_EXPENDITURE_ITEM_DATE) as CreationYear,

        --3
        EXTRACT(MONTH FROM pod.PJC_EXPENDITURE_ITEM_DATE) as CreationMonthText,

        --4
        TO_CHAR(pod.PJC_EXPENDITURE_ITEM_DATE, 'YYYY, MONTH') as CreationMonth,

        --5
        org.Name as Company,

        --6
        poh.Segment1 as OrderNumber,

        --7
        Initcap(poh.DOCUMENT_STATUS) as OrderDocumentStatus,

        --8
        Initcap(sup.VENDOR_NAME) as SuppName,

        --9
        pol.LINE_NUM as LineNumber,

        --10
        Initcap(pol.ATTRIBUTE1) as LineType,

        --11
        Initcap(Translate(pol.ITEM_DESCRIPTION, chr(10)||chr(11)||chr(13), '   '))   as LineDesc,

        --12
        valAccoutN.Description  || ' ' || glcode.Segment2   AccountDescTotal, 

        --13
        pol.UOM_CODE as   LineUnitCode,

        --14
        pol.Quantity as   LineQuantity,

        --15
        pol.Unit_PRICE as LineUnitPrice,

        --16
        Initcap(cate.Category_Name) Category_Name,

        --17
        Case 
        When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
        When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
        When proc.SEGMENT1 is not null Then proc.SEGMENT1
        When pod.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Common Expenses'
        When pod.ATTRIBUTE12 = 'INVT.LRMN.001' Then 'La Romana Common Expenses'
        When pod.ATTRIBUTE12 is not null Then SubPDesc.Description
        Else 'Non-Project'
        End
        as ProjectName,

        --18
        NVL(proct.Task_Number, 'Non-Task') as ProjectTaskName,

        --19
        Case 
        When poh.rate is null Then 1
        Else poh.rate 
        End as Rate,

        --20
        poh.CURRENCY_CODE,

        --21
        Case
        When org.Name not like 'DO%' Then Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2)
        Else Trunc((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2)
        End  as AmountOrderCurrency,

        --22
        Case
        When org.Name not like 'DO%' Then Trunc((pod.TAX_EXCLUSIVE_AMOUNT * NVL(pod.rate, 1)),2)
        Else Trunc((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT) * NVL(pod.rate, 1),2)
        End  as AmountLedgerCurrency,

        --23
        Case 
        When org.Name not like 'DO%'
        Then
            Case 
            WHEN poh.CURRENCY_CODE = 'USD' Then Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2)
            Else Trunc(Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2) / 
                Case
                When dorderrate.Conversion_Rate is not null then TRUNC(dorderrate.Conversion_Rate,2)
                Else (Select * From
                        (Select dorderratex.Conversion_Rate From gl_daily_rates dorderratex 
                        Where dorderratex.From_Currency = 'USD' and dorderratex.TO_Currency = poh.CURRENCY_CODE
                        And dorderratex.Conversion_Type = 'Corporate' and Trunc(dorderratex.CONVERSION_DATE) < Trunc(poh.Creation_date)
                        Order By dorderratex.Conversion_Rate) Where Rownum <= 1)
                End, 2)
            End
        Else 
            Case 
            WHEN poh.CURRENCY_CODE = 'USD' Then Trunc((RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2)
            Else Trunc(Trunc((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2) / 
                Case
                When dorderrate.Conversion_Rate is not null then TRUNC(dorderrate.Conversion_Rate,2)
                Else (Select * From
                        (Select dorderratex.Conversion_Rate From gl_daily_rates dorderratex 
                        Where dorderratex.From_Currency = 'USD' and dorderratex.TO_Currency = poh.CURRENCY_CODE
                        And dorderratex.Conversion_Type = 'Corporate' and Trunc(dorderratex.CONVERSION_DATE) < Trunc(poh.Creation_date)
                        Order By dorderratex.Conversion_Rate) Where Rownum <= 1)
                End, 2)
            End
        End AmountUSD,

        --24
        perf.Display_Name as Buyer,

        --25
        pod.PJC_EXPENDITURE_ITEM_DATE as ExpenditureItemDate,

        --26
        poh.CREATION_DATE as OrderCreationDate,

        --27
        poh.SUBMIT_DATE as OrderSubmitDate,

        --28
        poh.APPROVED_DATE as OrderApprovedDate,

        --29
        (Select pohx.CURRENCY_CODE
        From PO_HEADERS_ALL pohx Where poh.BILLTO_BU_ID = pohx.BILLTO_BU_ID and pohx.Rate is null and Rownum <= 1)
        as LedgerCurrency,

        --30
        NVL(costcat.Description,'Non-CostCat')     CostCatDesc,  

        --31
        NVL(membertype.Description, 'Non-MemberType')  MemberTypeExpd, 
        
        --32
        NVL(memberexp.Description, 'Non-Member')   MemberExpd,
        
        --33
        NVL(placeexp.Description, 'Non-Place')  PlaceExpd,

        --34
        NVL(processexp.Description, 'Non-Process')  ProcessExpd

        From PO_LINES_ALL pol
        Inner Join PO_HEADERS_ALL poh 
            Inner Join HR_ORGANIZATION_UNITS_F_TL  org 
            On poh.BILLTO_BU_ID = org.ORGANIZATION_ID and org.Language = 'US'
            Inner Join POZ_SUPPLIERS_V sup 
            On sup.VENDOR_ID = poh.VENDOR_ID
            Left Join gl_daily_rates dorderrate            
            ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
            And dorderrate.Conversion_Type = 'Corporate' 
            and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
            Inner Join PER_PERSON_NAMES_F perf 
            ON poh.Agent_Id = perf.PERSON_ID and perf.Name_Type = 'GLOBAL'
        ON pol.PO_HEADER_ID = poh.PO_HEADER_ID 
        Inner Join PO_DISTRIBUTIONS_ALL pod 
            -- Sub Project Left Join
            Left Join FND_VS_VALUES_B SubPValue
                Inner Join FND_VS_VALUES_TL SubPDesc
                ON SubPValue.VALUE_ID = SubPDesc.VALUE_ID
                and SubPDesc.LANGUAGE = fnd_Global.Current_Language
            ON pod.ATTRIBUTE12 = SubPValue.Value AND pod.ATTRIBUTE11 = SubPValue.INDEPENDENT_VALUE
            and SubPValue.ATTRIBUTE_CATEGORY = 'ACM_SubProject_VS'
            Left Join FND_VS_VALUES_VL costcat ON costcat.Value = pod.ATTRIBUTE1 and costcat.ATTRIBUTE_CATEGORY like 'ACM_Business_Function_VS' 
            Left Join FND_VS_VALUES_VL membertype ON membertype.Value = pod.ATTRIBUTE6 and membertype.ATTRIBUTE_CATEGORY like 'ACM_Member_Type_VS' 
            Left Join FND_VS_VALUES_VL memberexp ON memberexp.Value = pod.ATTRIBUTE7 and memberexp.INDEPENDENT_VALUE = pod.ATTRIBUTE6 and memberexp.ATTRIBUTE_CATEGORY like 'ACM_Member_VS' 
            Left Join FND_VS_VALUES_VL placeexp ON placeexp.Value = pod.ATTRIBUTE8 and placeexp.ATTRIBUTE_CATEGORY like 'ACM_Place_VS' 
            Left Join FND_VS_VALUES_VL processexp ON processexp.Value = pod.ATTRIBUTE13 and processexp.ATTRIBUTE_CATEGORY like 'ACM_ProcessType_VS' 
            Inner Join GL_CODE_COMBINATIONS glcode 
                    Inner Join FND_VS_VALUES_B valAccout
                        Inner Join FND_VS_VALUES_TL valAccoutN 
                        ON valAccout.Value_Id = valAccoutN.Value_Id 
                        and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language
                ON valAccout.Value = glcode.Segment2 and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
            ON pod.CODE_COMBINATION_ID  = glcode.CODE_COMBINATION_ID
            Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = pod.PJC_PROJECT_ID
            Left Join PJF_TASKS_V  proct ON proct.TASK_ID = pod.PJC_TASK_ID
        ON pol.PO_LINE_ID = pod.PO_LINE_ID and pod.PJC_EXPENDITURE_ITEM_DATE between NVL(:PeriodStartDate, To_Date('22.09.1992','dd.MM.yyyy')) and  NVL(:PeriodEndDate, To_Date('22.09.2092','dd.MM.yyyy'))
        Left join EGP_Categories_TL cate ON cate.Category_Id = pol.Category_Id and cate.LANGUAGE= 'US'
        Where pol.Line_Status in ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING', 'FINALLY CLOSED' )

    )

    Union

    -- Expense
    (
        Select

        -- 1 
        'Expense' as TypeRep,

        -- 2
        EXTRACT(YEAR FROM expline.START_DATE) as CreationYear,

        -- 3
        EXTRACT(MONTH FROM expline.START_DATE) as CreationMonthText,

        -- 4
        TO_CHAR(expline.START_DATE, 'YYYY, MONTH') as CreationMonth,

        -- 5
        hou.Name as Company,

        -- 6
        eer.EXPENSE_REPORT_NUM as OrderNumber,

        -- 7
        statuscodes.DISPLAYED_FIELD  as OrderDocumentStatus,

        --8
        perexp.Display_Name as SuppName,

        -- 9
        1 as LineNumber,

        --10
        'Expense Line' as LineType,

        --11
        expline.Description LineDesc,

        --12
        (accountexp.Description || ' ' || gcc.segment2) as AccountDescTotal,

        --13
        'EXP' as LineUnitCode,

        --14
        1 as LineQuantity,

        --15
        expline.RECEIPT_AMOUNT as LineUnitPrice,

        --16
        'Expense Category' as Category_Name,

        --17
        NVL(prj.SEGMENT1,'Non-Project') Project,

        --18
        NVL(proct.Task_Number, 'Non-Task') Task,

        --19
        expline.EXCHANGE_RATE Rate,

        --20
        expline.RECEIPT_CURRENCY_CODE CURRENCY_CODE,

        --21
        expline.RECEIPT_AMOUNT AmountOrderCurrency,

        --22
        expline.FUNC_CURRENCY_AMOUNT AmountLedgerCurrency,

        --23
        Case 
            WHEN expline.RECEIPT_CURRENCY_CODE = 'USD' Then Trunc((expline.RECEIPT_AMOUNT),2)
            Else Trunc(Trunc(expline.FUNC_CURRENCY_AMOUNT,2) / Trunc(dorderrate.Conversion_Rate,2) , 2)
        End AmountUSD,

        --24
        perexp.Display_Name as Buyer,

        --25
        expdist.PJC_Expenditure_Item_Date ExpenditureItemDate,

        --26
        eer.CREATION_DATE as OrderCreationDate,

        --27
        eer.REPORT_SUBMIT_DATE as OrderSubmitDate,

        --28
        eer.FINAL_APPROVAL_DATE as OrderApprovedDate,

        --29
        (Select pohx.CURRENCY_CODE
        From PO_HEADERS_ALL pohx Where eer.Org_Id = pohx.BILLTO_BU_ID and pohx.Rate is null and Rownum <= 1)
        as LedgerCurrency,

        --30
        NVL(costcat.Description,'Non-CostCat')     CostCatDesc,  

        --31
        NVL(membertype.Description, 'Non-MemberType')  MemberTypeExpd, 
        
        --32
        NVL(memberexp.Description, 'Non-Member')   MemberExpd,
        
        --33
        NVL(placeexp.Description, 'Non-Place')  PlaceExpd,

        --34
        NVL(processexp.Description, 'Non-Process')  ProcessExpd


        From EXM_EXPENSE_REPORTS eer
        Inner Join EXM_EXPENSES expline 
            Left Join FND_VS_VALUES_VL costcat ON costcat.Value = expline.ATTRIBUTE_CHAR1 and costcat.ATTRIBUTE_CATEGORY like 'ACM_Business_Function_VS' 
            Left Join FND_VS_VALUES_VL membertype ON membertype.Value = expline.ATTRIBUTE_CHAR6 and membertype.ATTRIBUTE_CATEGORY like 'ACM_Member_Type_VS' 
            Left Join FND_VS_VALUES_VL memberexp ON memberexp.Value = expline.ATTRIBUTE_CHAR7 and memberexp.INDEPENDENT_VALUE = expline.ATTRIBUTE_CHAR6 and memberexp.ATTRIBUTE_CATEGORY like 'ACM_Member_VS' 
            Left Join FND_VS_VALUES_VL placeexp ON placeexp.Value = expline.ATTRIBUTE_CHAR8 and placeexp.ATTRIBUTE_CATEGORY like 'ACM_Place_VS' 
            Left Join FND_VS_VALUES_VL processexp ON processexp.Value = expline.ATTRIBUTE_CHAR13 and processexp.ATTRIBUTE_CATEGORY like 'ACM_ProcessType_VS' 
            Left Join gl_daily_rates dorderrate            
            ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = (Select pohx.CURRENCY_CODE From PO_HEADERS_ALL pohx Where expline.Org_Id = pohx.BILLTO_BU_ID and pohx.Rate is null and Rownum <= 1)
            And dorderrate.Conversion_Type = 'Corporate' 
            and dorderrate.CONVERSION_DATE = 
                (Select 
                    dorderratex.CONVERSION_DATE From gl_daily_rates dorderratex 
                    Where dorderratex.From_Currency = 'USD' 
                    and dorderratex.TO_Currency = (Select pohx.CURRENCY_CODE From PO_HEADERS_ALL pohx Where expline.Org_Id = pohx.BILLTO_BU_ID 
                    and pohx.Rate is null and Rownum <= 1)   
                    and dorderratex.CONVERSION_DATE <= To_Date(To_Char(expline.START_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy') and Rownum <= 1 )
            Inner Join EXM_EXPENSE_DISTS expdist 
                Inner Join gl_code_combinations gcc
                    Inner Join FND_VS_VALUES_VL accountexp 
                    ON gcc.segment2 = accountexp.VALUE  and accountexp.ATTRIBUTE_CATEGORY like 'ACM_Account' 
                ON gcc.code_combination_id= expdist.code_combination_id and gcc.enabled_flag='Y'
                Left Join PJF_PROJECTS_ALL_VL prj
                    -- Inner Join PJF_PROJ_ELEMENTS_VL projel
                        -- Left Join PJT_COLUMN_LKP_VALUES_VL projcodemainp ON projel.TASK_CODE01_ID = projcodemainp.Code_value_Id and projcodemainp.Column_Map_Id = '300000011071779'
                        -- Left Join PJT_COLUMN_LKP_VALUES_VL projcodeloca ON projel.TASK_CODE02_ID = projcodeloca.Code_value_Id and projcodeloca.Column_Map_Id = '300000020011425'
                        -- Left Join PJT_COLUMN_LKP_VALUES_VL projcodecont ON projel.TASK_CODE03_ID = projcodecont.Code_value_Id and projcodecont.Column_Map_Id = '300000028309790'
                    -- On projel.Project_Id = prj.Project_Id and projel.OBJECT_TYPE = 'PJF_STRUCTURES'
                ON expdist.PJC_PROJECT_ID=prj.PROJECT_ID
                Left Join PJF_TASKS_V proct
                ON expdist.PJC_TASK_ID = proct.TASK_ID
            ON expdist.expense_id= expline.expense_id
        ON eer.expense_report_id = expline.expense_report_id
        Inner Join EXM_LOOKUP_VALUES statuscodes ON eer.EXPENSE_STATUS_CODE = statuscodes.LOOKUP_CODE and statuscodes.LOOKUP_TYPE = 'EXM_REPORT_STATUS' 
        Inner Join HR_ORGANIZATION_UNITS_F_TL hou  ON eer.Org_Id = hou.Organization_Id and hou.Language = 'US'
        Inner Join PER_PERSON_NAMES_F_V perexp ON perexp.PERSON_ID = eer.PERSON_ID and perexp.Name_Type = 'GLOBAL' and sysdate between perexp.Effective_Start_Date and perexp.Effective_End_Date 
        Where  statuscodes.DISPLAYED_FIELD IN ('Paid', 'Partially paid', 'Ready for payment', 'Pending expense auditor approval', 'Ready for payment processing')
        and expline.START_DATE between NVL(:PeriodStartDate, To_Date('22.09.1992','dd.MM.yyyy')) and  NVL(:PeriodEndDate, To_Date('22.09.2092','dd.MM.yyyy'))
    )


) ProjDetail

Where ProjDetail.Company IN (:CompanyName)
and ProjDetail.ProjectName IN (:ProjectX)
and ProjDetail.ProjectTaskName IN (:TaskX) 
and ProjDetail.MemberTypeExpd IN (:MemberTypeX)
and ProjDetail.MemberExpd In (:MemberX)

Order By ProjDetail.OrderCreationDate DESC, ProjDetail.LineNumber