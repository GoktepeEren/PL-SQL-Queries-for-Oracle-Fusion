With CategoryHier
As (Select
ItemAssign.INVENTORY_ITEM_ID as ItemId,
Initcap(Trim(CategoryFirst.Category_Name)) as CategoryNameFirst,
Initcap(Trim(NVL(CategorySecond.Category_Name ,CategoryFirst.Category_Name))) as CategoryNameSecond,
Initcap(Trim(NVL(CategoryThird.Category_Name ,NVL(CategorySecond.Category_Name ,CategoryFirst.Category_Name)))) as CategoryNameThird
From EGP_ITEM_CAT_ASSIGNMENTS ItemAssign
Inner Join EGP_CATEGORIES_VL CategoryFirst 
    Inner Join EGP_CATEGORY_SET_VALID_CATS CategoryHierUp
        Left Join EGP_CATEGORIES_VL CategorySecond
            Left Join EGP_CATEGORY_SET_VALID_CATS CategoryHierUp2
                Left Join EGP_CATEGORIES_VL CategoryThird 
                ON CategoryHierUp2.PARENT_CATEGORY_ID = CategoryThird.Category_Id 
            ON CategoryHierUp2.Category_Id = CategorySecond.Category_Id
        ON CategoryHierUp.Parent_Category_ID = CategorySecond.Category_Id
    ON CategoryHierUp.Category_ID = CategoryFirst.Category_Id
ON ItemAssign.CATEGORY_ID = CategoryFirst.Category_Id
Where ItemAssign.CATEGORY_SET_ID  = '300000013087480' and Trim(CategoryFirst.Category_Name) not like '%_OLD%')

SELECT

EXTRACT(YEAR FROM pod.PJC_EXPENDITURE_ITEM_DATE) as CreationYear,

EXTRACT(MONTH FROM pod.PJC_EXPENDITURE_ITEM_DATE) as CreationMonthText,

TO_CHAR(pod.PJC_EXPENDITURE_ITEM_DATE, 'YYYY, MONTH') as CreationMonth,

geo.GEOGRAPHY_ID,
org.LEGAL_ENTITY_ID ,

'World' as World,
geo.GEOGRAPHY_NAME  as Country,
org.Name as Company,

Case 
When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
When proc.SEGMENT1 is not null Then proc.SEGMENT1
When pod.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Common Expenses'
When pod.ATTRIBUTE12 = 'INVT.LRMN.001' Then 'La Romana Common Expenses'
When pod.ATTRIBUTE12 is not null Then SubPDesc.Description
Else 'UnselectedProject'
End
as ProjectName,

poh.Segment1 as OrderNumber,
poh.DOCUMENT_STATUS as OrderDocumentStatus,
sup.VENDOR_NAME as SuppName,
term.Name as Term_Name,

pol.LINE_NUM as LineNumber,
pol.ATTRIBUTE1 as LineType,
pol.ITEM_ID as ItemId,
Translate(pol.ITEM_DESCRIPTION, chr(10)||chr(11)||chr(13), '   ')   as LineDesc,
Initcap(cate.Category_Name) as Category_Name ,

(Case 
When pol.ITEM_ID is null Then Initcap(cate.Category_Name) 
Else CategoryHierarcy.CategoryNameFirst
End 
) as ItemCategory_Name,


(Case 
When pol.ITEM_ID is null Then 'Undefinable Item Category (Non-Catalog)'
When CategoryHierarcy.CategoryNameFirst is null Then 'Undefined Item Category'
Else CategoryHierarcy.CategoryNameSecond
End 
) as ItemCategory_Name1,


(Case 
When pol.ITEM_ID is null Then 'Undefinable Item Category (Non-Catalog)'
When CategoryHierarcy.CategoryNameFirst is null Then 'Undefined Item Category'
Else CategoryHierarcy.CategoryNameThird
End 
) as ItemCategory_Name2,


glcode.Segment2 as Account,
SUBSTR(glcode.Segment2, 1, 3)  as Account3,
SUBSTR(glcode.Segment2, 1, 7)  as Account7,
SUBSTR(glcode.Segment2, 1, 11) as Account11,


valAccoutN.Description as AccountDescription,
valAccoutN3.Description as AccountDescription3,
valAccoutN7.Description as AccountDescription7,
valAccoutN11.Description as AccountDescription11,

valAccoutN.Description || ' - ' || glcode.Segment2   as AccountTotal,
valAccoutN3.Description  || ' - ' || SUBSTR(glcode.Segment2, 1, 3)   as AccountTotal3,
valAccoutN7.Description  || ' - ' || SUBSTR(glcode.Segment2, 1, 7)   as AccountTotal7,
valAccoutN11.Description || ' - ' || SUBSTR(glcode.Segment2, 1, 11)   as AccountTotal11,

pol.UOM_CODE as LineUnitCode,
pol.Quantity as LineQuantity,
pol.Unit_PRICE as LineUnitPrice,



-- Sum
(Trunc((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2)) as AmountOrderCurrency,

(Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2)) as AmountOrderCurrencyWoutTax,

-- Sum
(Case 
WHEN poh.CURRENCY_CODE = 'USD' Then Trunc((RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2)
Else Trunc(Trunc((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2) / TRUNC(dorderrate.Conversion_Rate,2), 2)
End) AmountUSD,

(Case
When geo.GEOGRAPHY_NAME like 'Dominican%' Then
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
End) AmountUSDforPivot,

poh.CURRENCY_CODE,


perf.Display_Name as Buyer,

pod.PJC_EXPENDITURE_ITEM_DATE as ExpItemDate,
poh.CREATION_DATE as OrderCreationDate,
poh.SUBMIT_DATE as OrderSubmitDate,
poh.APPROVED_DATE as OrderApprovedDate

-- Can use for ungrouping query 

-- poh.Segment1 ponumber,

-- poh.PO_HEADER_ID poid,

-- pod.RECOVERABLE_INCLUSIVE_TAX,
-- pod.RECOVERABLE_TAX,
-- pod.TAX_EXCLUSIVE_AMOUNT,

-- poh.CURRENCY_CODE as Currency,

-- Case 
-- WHEN poh.CURRENCY_CODE = 'USD' Then 1
-- Else TRUNC(dorderrate.Conversion_Rate,2)
-- End as OrderRateUSD,

-- poh.CREATION_DATE

From PO_LINES_ALL pol
Inner Join PO_HEADERS_ALL poh 
	Inner Join XLE_ENTITY_PROFILES org 
        Inner Join HZ_GEOGRAPHIES geo 
        ON org.GEOGRAPHY_ID = geo.GEOGRAPHY_ID
    On poh.SOLDTO_LE_ID = org.LEGAL_ENTITY_ID -- and org.Language = 'US'
    Inner Join HR_ORGANIZATION_UNITS_F_TL  orgbu 
    On poh.BILLTO_BU_ID = orgbu.ORGANIZATION_ID and orgbu.Language = 'US' 
    Inner Join POZ_SUPPLIERS_V sup 
	On sup.VENDOR_ID = poh.VENDOR_ID
    Inner Join AP_TERMS_TL term 
	ON term.TERM_ID = poh.TERMS_ID And term.LANGUAGE = 'US'
	Left Join gl_daily_rates dorderrate            
	ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
	And dorderrate.Conversion_Type = 'Corporate' 
	and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
    Inner Join PER_PERSON_NAMES_F perf 
    ON poh.Agent_Id = perf.PERSON_ID and perf.Name_Type = 'GLOBAL' and Trunc(Sysdate) between perf.EFFECTIVE_START_DATE and perf.EFFECTIVE_End_DATE
ON pol.PO_HEADER_ID = poh.PO_HEADER_ID 
-- and poh.CREATION_DATE between (:PeriodStartDate) and  (:PeriodEndDate)
Inner Join PO_DISTRIBUTIONS_ALL pod 
    Left Join FND_VS_VALUES_B SubPValue
        Inner Join FND_VS_VALUES_TL SubPDesc
        ON SubPValue.VALUE_ID = SubPDesc.VALUE_ID
        and SubPDesc.LANGUAGE = fnd_Global.Current_Language
        ON pod.ATTRIBUTE12 = SubPValue.Value
        AND pod.ATTRIBUTE11 = SubPValue.INDEPENDENT_VALUE
    and SubPValue.ATTRIBUTE_CATEGORY = 'ACM_SubProject_VS'
    Inner Join GL_CODE_COMBINATIONS glcode 
			Inner Join FND_VS_VALUES_B valAccout
                Inner Join FND_VS_VALUES_TL valAccoutN 
                ON valAccout.Value_Id = valAccoutN.Value_Id 
                and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language
		ON valAccout.Value = glcode.Segment2 and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
        -- Account3
        Inner Join FND_VS_VALUES_B valAccout3
            Inner Join FND_VS_VALUES_TL valAccoutN3 
            ON valAccout3.Value_Id = valAccoutN3.Value_Id 
            and valAccoutN3.LANGUAGE= FND_GLOBAL.Current_Language
        ON valAccout3.Value = SUBSTR(glcode.Segment2, 1, 3) and valAccout3.ATTRIBUTE_CATEGORY = 'ACM_Account'
        -- Account7
        Inner Join FND_VS_VALUES_B valAccout7
            Inner Join FND_VS_VALUES_TL valAccoutN7
            ON valAccout7.Value_Id = valAccoutN7.Value_Id 
            and valAccoutN7.LANGUAGE= FND_GLOBAL.Current_Language
        ON valAccout7.Value = SUBSTR(glcode.Segment2, 1, 7) and valAccout7.ATTRIBUTE_CATEGORY = 'ACM_Account'
        -- Account11
        Inner Join FND_VS_VALUES_B valAccout11
            Inner Join FND_VS_VALUES_TL valAccoutN11
            ON valAccout11.Value_Id = valAccoutN11.Value_Id 
            and valAccoutN11.LANGUAGE= FND_GLOBAL.Current_Language
        ON valAccout11.Value = SUBSTR(glcode.Segment2, 1, 11) and valAccout11.ATTRIBUTE_CATEGORY = 'ACM_Account'

    ON pod.CODE_COMBINATION_ID  = glcode.CODE_COMBINATION_ID
ON pol.PO_LINE_ID = pod.PO_LINE_ID 
-- and pod.PJC_EXPENDITURE_ITEM_DATE >= to_date('01.06.2020', 'dd.MM.yyyy')
Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = pod.PJC_PROJECT_ID
-- Purchasing Category
Left join EGP_CATEGORIES_VL cate ON cate.Category_Id = pol.Category_Id
-- Item Category
Left Join CategoryHier CategoryHierarcy ON CategoryHierarcy.ItemId = pol.ITEM_ID 

Where pol.Line_Status in ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
and pod.PJC_EXPENDITURE_ITEM_DATE Between Trunc(NVL(:StartDate,To_Date('22.09.1992','dd.MM.yyyy'))) and Trunc(NVL(:EndDate,To_Date('22.09.2050','dd.MM.yyyy')))
and glcode.Segment2 not like '198%'

and (orgbu.Name IN 

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

Order By pod.PJC_EXPENDITURE_ITEM_DATE DESC, pol.LINE_NUM