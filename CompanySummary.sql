SELECT

EXTRACT(YEAR FROM poh.CREATION_DATE) as CreationYear,

EXTRACT(MONTH FROM poh.CREATION_DATE) as CreationMonthText,

TO_CHAR(poh.CREATION_DATE, 'YYYY, MONTH') as CreationMonth,

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
When catitem.Category_Name is null Then 'Undefined Item Category' 
Else Initcap(catitem.Category_Name)
End 
) as ItemCategory_Name,


(Case 
When pol.ITEM_ID is null Then Initcap(cate.Category_Name)
When catitem.Category_Name is null Then 'Undefined Item Category' 
When cateman.Category_Name is null Then 'Undefined Item Category'
Else Initcap(cateman.Category_Name)
End 
) as ItemCategory_Name1,


(Case 
When pol.ITEM_ID is null Then Initcap(cate.Category_Name)
When catitem.Category_Name is null Then 'Undefined Item Category' 
When cateman.Category_Name is null Then 'Undefined Item Category'
When cateman2.Category_Name is null Then Initcap(cateman.Category_Name) 
Else Initcap(cateman2.Category_Name)
End 
) as ItemCategory_Name2,

-- Optional can added
(Case 
When pol.ITEM_ID is null Then 'Undefinable Item Category (Non-Catalog)'
When catitem.Category_Name is null Then 'Undefined Item Category' 
When cateman.Category_Name is null Then 'Undefined Item Category'
When cateman2.Category_Name is null Then  Initcap(cateman.Category_Name) 
When cateman3.Category_Name is null Then  Initcap(cateman2.Category_Name) 
Else  Initcap(cateman3.Category_Name)
End 
) as ItemCategory_Name3,


-- cateman.Category_Name as ItemCategory_Name1,
-- cateman2.Category_Name as ItemCategory_Name2,
-- cateman3.Category_Name as ItemCategory_Name3,


glcode.Segment2 as Account,
SUBSTR(glcode.Segment2, 1, 3)  as Account3,
SUBSTR(glcode.Segment2, 1, 7)  as Account7,
SUBSTR(glcode.Segment2, 1, 11) as Account11,


valAccoutN.Description as AccountDescription,
valAccoutN3.Description as AccountDescription3,
valAccoutN7.Description as AccountDescription7,
valAccoutN11.Description as AccountDescription11,

glcode.Segment2 || ' - ' || valAccoutN.Description as AccountTotal,
SUBSTR(glcode.Segment2, 1, 3)   || ' - ' || valAccoutN3.Description as AccountTotal3,
SUBSTR(glcode.Segment2, 1, 7)   || ' - ' || valAccoutN7.Description as AccountTotal7,
SUBSTR(glcode.Segment2, 1, 11)  || ' - ' || valAccoutN11.Description as AccountTotal11,

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
    On poh.SOLDTO_LE_ID = org.LEGAL_ENTITY_ID 
-- and org.Language = 'US'
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
ON pol.PO_HEADER_ID = poh.PO_HEADER_ID and poh.CREATION_DATE >= to_date('01.06.2020', 'dd.MM.yyyy')
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
Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = pod.PJC_PROJECT_ID
-- Purchasing Category
Left join EGP_Categories_TL cate ON cate.Category_Id = pol.Category_Id and cate.LANGUAGE= 'US'
-- Item Category
Left Join EGP_ITEM_CAT_ASSIGNMENTS icatitemcat
    Inner Join EGP_CATEGORIES_VL catitem 
        Left Join EGP_CATEGORY_SET_VALID_CATS valid
            Left Join EGP_Categories_TL cateman 
                Left Join EGP_CATEGORY_SET_VALID_CATS valid2
                    Left Join EGP_Categories_TL cateman2 
                        -- Optioanlly can added
                        Left Join EGP_CATEGORY_SET_VALID_CATS valid3
                            Left Join EGP_Categories_TL cateman3 
                            ON valid3.PARENT_CATEGORY_ID = cateman3.Category_Id and cateman3.LANGUAGE= 'US'
                        ON valid3.Category_Id = cateman2.Category_Id
                    ON valid2.PARENT_CATEGORY_ID = cateman2.Category_Id and cateman2.LANGUAGE= 'US'
                ON valid2.Category_Id = cateman.Category_Id
            ON valid.PARENT_CATEGORY_ID = cateman.Category_Id and cateman.LANGUAGE= 'US'
        ON valid.Category_ID = catitem.Category_Id
    ON icatitemcat.Category_Id = catitem.Category_Id and (catitem.END_DATE_ACTIVE is null OR catitem.END_DATE_ACTIVE > sysdate)   
ON pol.ITEM_ID = icatitemcat.Inventory_Item_Id and icatitemcat.CATEGORY_SET_ID  = '300000013087480'



Where pol.Line_Status in ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')

-- and EXTRACT(YEAR FROM poh.CREATION_DATE) = 2020 
-- and EXTRACT(MONTH FROM poh.CREATION_DATE) IN (3,4)
-- and org.Name IN (:CompanyName)
-- Group By 
-- EXTRACT(YEAR FROM poh.CREATION_DATE), EXTRACT(MONTH FROM poh.CREATION_DATE), TO_CHAR(poh.CREATION_DATE, 'YYYY, MONTH') , org.Name, proc.SEGMENT1, poh.CURRENCY_CODE
Order By poh.Creation_date DESC, pol.LINE_NUM