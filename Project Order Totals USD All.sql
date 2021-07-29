Select

ProjectGraphV3.Project,
Sum(ProjectGraphV3.AmountUSD) AmountUSD

From
(SELECT

-- TO_CHAR(NVL(pod.PJC_EXPENDITURE_ITEM_DATE, poh.Creation_date), 'YYYY, MONTH') as ExpItemMonth,

org.Name as Company,

-- Translate(pol.ITEM_DESCRIPTION, chr(10)||chr(11)||chr(13), '   ')   as ItemDescription,

-- cate.Category_Name as Category,

Case 
When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Projects Common'
When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Projects Common'
When proc.SEGMENT1 is not null Then proc.SEGMENT1
When pod.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Projects Common'
When pod.ATTRIBUTE12 = 'INVT.LRMN.001' Then 'La Romana Projects Common'
When pod.ATTRIBUTE12 is not null Then SubPDesc.Description
Else 'Non-Project'
End
as Project,


-- Case
-- When NVL(costcat.Description, 'Non-CostCat') = 'Own Department' Then 'Other'
-- Else NVL(costcat.Description, 'Non-CostCat') End  CostCat,

-- NVL(Replace(exporg.Name, '_', ''), 'Non-Organization') ExpOrg,

-- Sum
(Case
When org.Name like 'DO%' Then
    (Case 
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
    End)
Else
    (Case 
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
    End)
End) AmountUSD


-- NVL(pod.PJC_EXPENDITURE_ITEM_DATE, poh.Creation_date) as ExpenditureItemDate

From PO_LINES_ALL pol
Inner Join PO_HEADERS_ALL poh 
	Inner Join HR_ORGANIZATION_UNITS_F_TL  org 
	On poh.BILLTO_BU_ID = org.ORGANIZATION_ID and org.Language = 'US'
    Left Join gl_daily_rates dorderrate            
	ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
	And dorderrate.Conversion_Type = 'Corporate' 
	and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
ON pol.PO_HEADER_ID = poh.PO_HEADER_ID and poh.Document_Status in ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING', 'FINALLY CLOSED')
Inner Join PO_DISTRIBUTIONS_ALL pod 
    Left Join FND_VS_VALUES_B SubPValue
        Inner Join FND_VS_VALUES_TL SubPDesc
        ON SubPValue.VALUE_ID = SubPDesc.VALUE_ID
        and SubPDesc.LANGUAGE = fnd_Global.Current_Language
        ON pod.ATTRIBUTE12 = SubPValue.Value
        AND pod.ATTRIBUTE11 = SubPValue.INDEPENDENT_VALUE
    and SubPValue.ATTRIBUTE_CATEGORY = 'ACM_SubProject_VS'
    -- and horghead.ATTRIBUTE3 like '%Direktörlük%'
ON pol.PO_LINE_ID = pod.PO_LINE_ID 
Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = pod.PJC_PROJECT_ID

Where NVL( poh.CREATION_DATE, pod.PJC_EXPENDITURE_ITEM_DATE) between NVL(:PeriodStartDate, To_Date('22.09.1992','dd.MM.yyyy')) and  NVL(:PeriodEndDate, To_Date('22.09.2092','dd.MM.yyyy')) 
and (org.Name IN (:Company) OR 'All' IN (:Company || 'All'))
-- Authorization: Purchase Analysis Role - Business Unit --
and (org.Name IN 

    (Select
horg.Name BusinessUnit
From
PER_USERS users
Inner Join PER_USER_ROLES roles
    Inner Join PER_ROLES_DN_VL rolesdetail
        Inner Join FUN_USER_ROLE_DATA_ASGNMNTS accdata
            Inner Join hr_organization_units horg
            ON horg.Organization_Id = accdata.Org_Id
        On rolesdetail.Role_Common_Name = accdata.ROLE_NAME and accdata.ACTIVE_FLAG = 'Y' 
    ON rolesdetail.Role_ID = roles.Role_Id 
ON users.USER_ID = roles.User_ID
Where accdata.USER_GUID = users.USER_GUID
and rolesdetail.ROLE_COMMON_NAME = 'ORA_PO_PURCHASE_ANALYSIS_ABSTRACT'
and users.UserName = fnd_global.USER_Name ))
-- Authorization: Purchase Analysis Role - Business Unit --
) ProjectGraphV3

Where (ProjectGraphV3.Project IN (:Project) OR 'All' IN (:Project || 'All'))

GROUP BY ProjectGraphV3.Project

------------------------------------------


Select

*

From

    (Select

    ProjectGraphV3_1.ReportType,
    Sum(ProjectGraphV3_1.AmountUSD) as TotalAmountUSD

    From

        (Select

        ProjectGraphV3.Project,
        Case 
        When (:ReportType) = 'CostCat' Then ProjectGraphV3.CostCat
        Else ProjectGraphV3.ExpOrg
        End as ReportType,
        ProjectGraphV3.AmountUSD

        From
        (SELECT

        -- TO_CHAR(NVL(pod.PJC_EXPENDITURE_ITEM_DATE, poh.Creation_date), 'YYYY, MONTH') as ExpItemMonth,

        org.Name as Company,

        -- Translate(pol.ITEM_DESCRIPTION, chr(10)||chr(11)||chr(13), '   ')   as ItemDescription,

        -- cate.Category_Name as Category,

        Case 
        When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Projects Common'
        When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Projects Common'
        When proc.SEGMENT1 is not null Then proc.SEGMENT1
        When pod.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Projects Common'
        When pod.ATTRIBUTE12 = 'INVT.LRMN.001' Then 'La Romana Projects Common'
        When pod.ATTRIBUTE12 is not null Then SubPDesc.Description
        Else 'Non-Project'
        End
        as Project,


        Case
        When NVL(costcat.Description, 'Non-CostCat') = 'Own Department' Then 'Other'
        Else NVL(costcat.Description, 'Non-CostCat') End  CostCat,

        NVL(Replace(exporg.Name, '_', ''), 'Non-Organization') ExpOrg,

        -- Sum
        (Case
        When org.Name like 'DO%' Then
            (Case 
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
            End)
        Else
            (Case 
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
            End)
        End) AmountUSD


        -- NVL(pod.PJC_EXPENDITURE_ITEM_DATE, poh.Creation_date) as ExpenditureItemDate

        From PO_LINES_ALL pol
        Inner Join PO_HEADERS_ALL poh 
            Inner Join HR_ORGANIZATION_UNITS_F_TL  org 
            On poh.BILLTO_BU_ID = org.ORGANIZATION_ID and org.Language = 'US'
            Left Join gl_daily_rates dorderrate            
            ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
            And dorderrate.Conversion_Type = 'Corporate' 
            and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
        ON pol.PO_HEADER_ID = poh.PO_HEADER_ID and poh.Document_Status in ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING', 'FINALLY CLOSED')
        Inner Join PO_DISTRIBUTIONS_ALL pod 
            Left Join FND_VS_VALUES_B SubPValue
                Inner Join FND_VS_VALUES_TL SubPDesc
                ON SubPValue.VALUE_ID = SubPDesc.VALUE_ID
                and SubPDesc.LANGUAGE = fnd_Global.Current_Language
                ON pod.ATTRIBUTE12 = SubPValue.Value
                AND pod.ATTRIBUTE11 = SubPValue.INDEPENDENT_VALUE
            and SubPValue.ATTRIBUTE_CATEGORY = 'ACM_SubProject_VS'
            Left Join FND_VS_VALUES_VL costcat ON costcat.Value = pod.ATTRIBUTE1 and costcat.ATTRIBUTE_CATEGORY like 'ACM_Business_Function_VS' 
            Left Join HR_ORGANIZATION_V exporg
            ON pod.PJC_ORGANIZATION_ID = exporg.ORGANIZATION_ID  and exporg.CLASSIFICATION_CODE='DEPARTMENT' and exporg.STATUS='A'
            and Trunc(Sysdate) between Trunc(exporg.EFFECTIVE_START_DATE) and Trunc(exporg.EFFECTIVE_END_DATE) 
            -- and horghead.ATTRIBUTE3 like '%Direktörlük%'
        ON pol.PO_LINE_ID = pod.PO_LINE_ID 
        Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = pod.PJC_PROJECT_ID
        -- Left join EGP_Categories_TL cate ON cate.Category_Id = pol.Category_Id and cate.LANGUAGE= 'US'

        Where NVL(poh.CREATION_DATE, pod.PJC_EXPENDITURE_ITEM_DATE) between NVL(:PeriodStartDate, To_Date('22.09.1992','dd.MM.yyyy')) and  NVL(:PeriodEndDate, To_Date('22.09.2092','dd.MM.yyyy')) 
        -- Authorization: Purchase Analysis Role - Business Unit --
        and (org.Name IN 
            (Select
        horg.Name BusinessUnit
        From
        PER_USERS users
        Inner Join PER_USER_ROLES roles
            Inner Join PER_ROLES_DN_VL rolesdetail
                Inner Join FUN_USER_ROLE_DATA_ASGNMNTS accdata
                    Inner Join hr_organization_units horg
                    ON horg.Organization_Id = accdata.Org_Id
                On rolesdetail.Role_Common_Name = accdata.ROLE_NAME and accdata.ACTIVE_FLAG = 'Y' 
            ON rolesdetail.Role_ID = roles.Role_Id 
        ON users.USER_ID = roles.User_ID
        Where accdata.USER_GUID = users.USER_GUID
        and rolesdetail.ROLE_COMMON_NAME = 'ORA_PO_PURCHASE_ANALYSIS_ABSTRACT'
        and users.UserName = fnd_global.USER_Name ))
        -- Authorization: Purchase Analysis Role - Business Unit --
    ) ProjectGraphV3

    Where (ProjectGraphV3.Project IN (:Project) OR 'All' IN (:Project || 'All')) 
    and (ProjectGraphV3.Company IN (:Company) OR 'All' IN (:Company || 'All')))  ProjectGraphV3_1

GROUP By ProjectGraphV3_1.ReportType

Order By Sum(ProjectGraphV3_1.AmountUSD) Desc)

-----------------------------------------------------------

Select

*

From

    (Select

    Initcap(ProjectGraphV3_1.Category) Category,
    Sum(ProjectGraphV3_1.AmountUSD) TotalAmountUSD

    From

        (Select

        ProjectGraphV3.Project,
        Case 
        When (:ReportType) = 'CostCat' Then ProjectGraphV3.CostCat
        Else ProjectGraphV3.ExpOrg
        End as ReportType,
        ProjectGraphV3.Category,
        ProjectGraphV3.AmountUSD

        From
        (SELECT

        -- TO_CHAR(NVL(pod.PJC_EXPENDITURE_ITEM_DATE, poh.Creation_date), 'YYYY, MONTH') as ExpItemMonth,

        org.Name as Company,

        -- Translate(pol.ITEM_DESCRIPTION, chr(10)||chr(11)||chr(13), '   ')   as ItemDescription,

        cate.Category_Name as Category,

        Case 
        When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Projects Common'
        When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Projects Common'
        When proc.SEGMENT1 is not null Then proc.SEGMENT1
        When pod.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Projects Common'
        When pod.ATTRIBUTE12 = 'INVT.LRMN.001' Then 'La Romana Projects Common'
        When pod.ATTRIBUTE12 is not null Then SubPDesc.Description
        Else 'Non-Project'
        End
        as Project,


        Case
        When NVL(costcat.Description, 'Non-CostCat') = 'Own Department' Then 'Other'
        Else NVL(costcat.Description, 'Non-CostCat') End  CostCat,

        NVL(Replace(exporg.Name, '_', ''), 'Non-Organization') ExpOrg,

        -- Sum
        (Case
        When org.Name like 'DO%' Then
            (Case 
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
            End)
        Else
            (Case 
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
            End)
        End) AmountUSD


        -- NVL(pod.PJC_EXPENDITURE_ITEM_DATE, poh.Creation_date) as ExpenditureItemDate

        From PO_LINES_ALL pol
        Inner Join PO_HEADERS_ALL poh 
            Inner Join HR_ORGANIZATION_UNITS_F_TL  org 
            On poh.BILLTO_BU_ID = org.ORGANIZATION_ID and org.Language = 'US'
            Left Join gl_daily_rates dorderrate            
            ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
            And dorderrate.Conversion_Type = 'Corporate' 
            and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
        ON pol.PO_HEADER_ID = poh.PO_HEADER_ID and poh.Document_Status in ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING', 'FINALLY CLOSED')
        Inner Join PO_DISTRIBUTIONS_ALL pod 
            Left Join FND_VS_VALUES_B SubPValue
                Inner Join FND_VS_VALUES_TL SubPDesc
                ON SubPValue.VALUE_ID = SubPDesc.VALUE_ID
                and SubPDesc.LANGUAGE = fnd_Global.Current_Language
                ON pod.ATTRIBUTE12 = SubPValue.Value
                AND pod.ATTRIBUTE11 = SubPValue.INDEPENDENT_VALUE
            and SubPValue.ATTRIBUTE_CATEGORY = 'ACM_SubProject_VS'
            Left Join FND_VS_VALUES_VL costcat ON costcat.Value = pod.ATTRIBUTE1 and costcat.ATTRIBUTE_CATEGORY like 'ACM_Business_Function_VS' 
            Left Join HR_ORGANIZATION_V exporg
            ON pod.PJC_ORGANIZATION_ID = exporg.ORGANIZATION_ID  and exporg.CLASSIFICATION_CODE='DEPARTMENT' and exporg.STATUS='A'
            and Trunc(Sysdate) between Trunc(exporg.EFFECTIVE_START_DATE) and Trunc(exporg.EFFECTIVE_END_DATE) 
            -- and horghead.ATTRIBUTE3 like '%Direktörlük%'
        ON pol.PO_LINE_ID = pod.PO_LINE_ID 
        Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = pod.PJC_PROJECT_ID
        Left join EGP_Categories_TL cate ON cate.Category_Id = pol.Category_Id and cate.LANGUAGE= 'US'

        Where NVL(poh.CREATION_DATE, pod.PJC_EXPENDITURE_ITEM_DATE) between NVL(:PeriodStartDate, To_Date('22.09.1992','dd.MM.yyyy')) and  NVL(:PeriodEndDate, To_Date('22.09.2092','dd.MM.yyyy')) 
        -- Authorization: Purchase Analysis Role - Business Unit --
        and (org.Name IN 

            (Select
        horg.Name BusinessUnit
        From
        PER_USERS users
        Inner Join PER_USER_ROLES roles
            Inner Join PER_ROLES_DN_VL rolesdetail
                Inner Join FUN_USER_ROLE_DATA_ASGNMNTS accdata
                    Inner Join hr_organization_units horg
                    ON horg.Organization_Id = accdata.Org_Id
                On rolesdetail.Role_Common_Name = accdata.ROLE_NAME and accdata.ACTIVE_FLAG = 'Y' 
            ON rolesdetail.Role_ID = roles.Role_Id 
        ON users.USER_ID = roles.User_ID
        Where accdata.USER_GUID = users.USER_GUID
        and rolesdetail.ROLE_COMMON_NAME = 'ORA_PO_PURCHASE_ANALYSIS_ABSTRACT'
        and users.UserName = fnd_global.USER_Name ))
        -- Authorization: Purchase Analysis Role - Business Unit --
        ) ProjectGraphV3

    Where (ProjectGraphV3.Project IN (:Project) OR 'All' IN (:Project || 'All')) 
    and (ProjectGraphV3.Company IN (:Company) OR 'All' IN (:Company || 'All'))
    and ((Case When (:ReportType) = 'CostCat' Then ProjectGraphV3.CostCat Else ProjectGraphV3.ExpOrg END) IN (:CostCatExpOrg) OR 'All' IN (:CostCatExpOrg || 'All'))



    )  ProjectGraphV3_1

GROUP By ProjectGraphV3_1.Category

Order By Sum(ProjectGraphV3_1.AmountUSD) Desc)