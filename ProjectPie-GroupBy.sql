SELECT

EXTRACT(YEAR FROM poh.CREATION_DATE) as CreationYear,

EXTRACT(MONTH FROM poh.CREATION_DATE) as CreationMonthText,

TO_CHAR(poh.CREATION_DATE, 'YYYY, MONTH') as CreationMonth,

org.Name as Company,

poh.Document_Status as DocumentStatus, 

cate.Category_Name,

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

poh.CURRENCY_CODE,

Case
When org.Name not like 'DO%' Then Sum(Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2))
Else Sum(Trunc((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2))
End  as AmountOrderCurrency,

Case 
When org.Name not like 'DO%'
Then
    Sum(Case 
    WHEN poh.CURRENCY_CODE = 'USD' Then Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2)
    Else Trunc(Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2) / TRUNC(dorderrate.Conversion_Rate,2), 2)
    End)
Else 
    Sum(Case 
    WHEN poh.CURRENCY_CODE = 'USD' Then Trunc((RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2)
    Else Trunc(Trunc((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2) / TRUNC(dorderrate.Conversion_Rate,2), 2)
    End) 
End AmountUSD


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
	Left Join gl_daily_rates dorderrate            
	ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
	And dorderrate.Conversion_Type = 'Corporate' 
	and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
ON pol.PO_HEADER_ID = poh.PO_HEADER_ID and poh.CREATION_DATE between (:PeriodStartDate) and  (:PeriodEndDate)
Inner Join PO_DISTRIBUTIONS_ALL pod 
    -- Sub Project Left Join
    Left Join FND_VS_VALUES_B SubPValue
	Inner Join FND_VS_VALUES_TL SubPDesc
	ON SubPValue.VALUE_ID = SubPDesc.VALUE_ID
	and SubPDesc.LANGUAGE = fnd_Global.Current_Language
    ON pod.ATTRIBUTE12 = SubPValue.Value
    AND pod.ATTRIBUTE11 = SubPValue.INDEPENDENT_VALUE
    and SubPValue.ATTRIBUTE_CATEGORY = 'ACM_SubProject_VS'
ON pol.PO_LINE_ID = pod.PO_LINE_ID
Left join EGP_Categories_TL cate ON cate.Category_Id = pol.Category_Id and cate.LANGUAGE= 'US'
Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = pod.PJC_PROJECT_ID
Where pol.Line_Status in ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
and org.Name IN (:CompanyName)
and 
(
Case 
When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
When proc.SEGMENT1 is not null Then proc.SEGMENT1
When pod.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Common Expenses'
When pod.ATTRIBUTE12 = 'INVT.LRMN.001' Then 'La Romana Common Expenses'
When pod.ATTRIBUTE12 is not null Then SubPDesc.Description
Else 'UnselectedProject'
End
)  In (:ProjectX)
and 'Graph' = (:GraphOrDetail)
Group By 
EXTRACT(YEAR FROM poh.CREATION_DATE), 
EXTRACT(MONTH FROM poh.CREATION_DATE), 
TO_CHAR(poh.CREATION_DATE, 'YYYY, MONTH') , 
org.Name, 
cate.Category_Name,
(Case 
When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
When proc.SEGMENT1 is not null Then proc.SEGMENT1
When pod.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Common Expenses'
When pod.ATTRIBUTE12 = 'INVT.LRMN.001' Then 'La Romana Common Expenses'
When pod.ATTRIBUTE12 is not null Then SubPDesc.Description
Else 'UnselectedProject'
End), 
poh.Document_Status,
poh.CURRENCY_CODE
Order By 
(Case 
When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
When proc.SEGMENT1 is not null Then proc.SEGMENT1
When pod.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Common Expenses'
When pod.ATTRIBUTE12 = 'INVT.LRMN.001' Then 'La Romana Common Expenses'
When pod.ATTRIBUTE12 is not null Then SubPDesc.Description
Else 'UnselectedProject'
End)