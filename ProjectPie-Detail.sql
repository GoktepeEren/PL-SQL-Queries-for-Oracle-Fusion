SELECT

-- EXTRACT(YEAR FROM poh.CREATION_DATE) as CreationYear,

-- EXTRACT(MONTH FROM poh.CREATION_DATE) as CreationMonthText,

TO_CHAR(poh.CREATION_DATE, 'YYYY, MONTH') as CreationMonth,

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
Translate(pol.ITEM_DESCRIPTION, chr(10)||chr(11)||chr(13), '   ')   as LineDesc,
cate.Category_Name,


glcode.Segment2 as Account,
valAccoutN.Description as AccountDescription,

glcode.Segment2 || ' ' || valAccoutN.Description  AccountDescTotal, 

pol.UOM_CODE as LineUnitCode,
pol.Quantity as LineQuantity,
pol.Unit_PRICE as LineUnitPrice,




-- Sum
Case
When org.Name not like 'DO%' Then (Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2))
Else (Trunc((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2))
End as AmountOrderCurrency,

Case 
When poh.rate is null Then 1
Else poh.rate 
End as rate,

poh.CURRENCY_CODE,

((Case
When org.Name not like 'DO%' Then (Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2))
Else (Trunc((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2))
End) *
(Case 
When poh.rate is null Then 1
Else poh.rate 
End)) as AmountLedger,

(SELECT
pohx.CURRENCY_CODE
From PO_HEADERS_ALL pohx
Where poh.BILLTO_BU_ID = pohx.BILLTO_BU_ID 
and  pohx.rate is null 
and rownum <= 1) as CurrencyLedger,


-- Sum
Case 
When org.Name not like 'DO%' Then 
    (Case 
    WHEN poh.CURRENCY_CODE = 'USD' Then Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2)
    Else Trunc(Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2) / TRUNC(dorderrate.Conversion_Rate,2), 2)
    End)
Else
    (Case 
    WHEN poh.CURRENCY_CODE = 'USD' Then Trunc((RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2)
    Else Trunc(Trunc((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2) / TRUNC(dorderrate.Conversion_Rate,2), 2)
    End)
End  AmountUSD,




perf.Display_Name as Buyer,
pod.PJC_EXPENDITURE_ITEM_DATE as ExpenditureItemDate,
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
	Inner Join HR_ORGANIZATION_UNITS_F_TL  org 
	On poh.BILLTO_BU_ID = org.ORGANIZATION_ID and org.Language = 'US'
    Inner Join POZ_SUPPLIERS_V sup 
	On sup.VENDOR_ID = poh.VENDOR_ID
    Inner Join AP_TERMS_TL term 
	ON term.TERM_ID = poh.TERMS_ID And term.LANGUAGE = 'US'
	Left Join gl_daily_rates dorderrate            
	ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
	And dorderrate.Conversion_Type = 'Corporate' 
	and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
    Inner Join PER_PERSON_NAMES_F perf 
    ON poh.Agent_Id = perf.PERSON_ID and perf.Name_Type = 'GLOBAL'
ON pol.PO_HEADER_ID = poh.PO_HEADER_ID and poh.CREATION_DATE between (:PeriodStartDate) and  (:PeriodEndDate)
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
	ON pod.CODE_COMBINATION_ID  = glcode.CODE_COMBINATION_ID
ON pol.PO_LINE_ID = pod.PO_LINE_ID
Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = pod.PJC_PROJECT_ID
Left join EGP_Categories_TL cate ON cate.Category_Id = pol.Category_Id and cate.LANGUAGE= 'US'


Where pol.Line_Status in ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
and org.Name IN (:CompanyName)
and 'Detail' = (:GraphOrDetail)
and 
(Case 
When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
When proc.SEGMENT1 is not null Then proc.SEGMENT1
When pod.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Common Expenses'
When pod.ATTRIBUTE12 = 'INVT.LRMN.001' Then 'La Romana Common Expenses'
When pod.ATTRIBUTE12 is not null Then SubPDesc.Description
Else 'UnselectedProject'
End) In (:ProjectX)
-- and EXTRACT(YEAR FROM poh.CREATION_DATE) = 2020 
-- and EXTRACT(MONTH FROM poh.CREATION_DATE) IN (3,4)
-- and org.Name IN (:CompanyName)
-- Group By 
-- EXTRACT(YEAR FROM poh.CREATION_DATE), EXTRACT(MONTH FROM poh.CREATION_DATE), TO_CHAR(poh.CREATION_DATE, 'YYYY, MONTH') , org.Name, proc.SEGMENT1, poh.CURRENCY_CODE
Order By poh.Creation_date DESC, pol.LINE_NUM