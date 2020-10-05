-- Invoice All
Select 
FromInvoices.*
From 
(
SELECT
Distinct
inhead.ORG_ID as OrgId,
horg.Name as BusinessUnit,

inline.Invoice_Id,
inhead.INVOICE_NUM as InvoiceNumber,

inhead.Invoice_Type_Lookup_Code as InvoiceType,
Translate(inhead.Description, chr(10)||chr(11)||chr(13), '   ') as InvoiceDescription,

inhead.VENDOR_ID as SupplierId,
inhead.VENDOR_SITE_ID as SupplierSiteId,
sup.VENDOR_NAME as SuppName,
sup.VENDOR_TYPE_LOOKUP_CODE as VendorType,
supsite.PARTY_SITE_NAME as SuppSiteName,

inhead.Terms_Id,
term.Name as Term_Name,

inline.Line_Type_Lookup_Code as InvoiceLineType,
inline.Line_Number as InvoiceLineNumber,
inline.Line_Source as LineSource,


inline.PO_HEADER_ID,
inline.PO_LINE_ID,


Case 
When inline.PO_HEADER_ID is not null Then orderdist.CODE_COMBINATION_ID 
Else indist.DIST_CODE_COMBINATION_ID 
End as CodeId,

Case 
When inline.PO_HEADER_ID is not null Then SUBSTR(glcodeordist.Segment2,1,3) 
Else SUBSTR(glcode.Segment2, 1,3) 
End as AccountFirstThree,

Case 
When inline.PO_HEADER_ID is not null Then SUBSTR(glcodeordist.Segment2,1,3) 
Else SUBSTR(glcode.Segment2, 1,3) 
End || ' - ' ||
(Select
firstthree.Description
From FND_VS_VALUES_B valAccout
    Inner Join FND_VS_VALUES_TL firstthree 
    ON valAccout.Value_Id = firstthree.Value_Id 
    and firstthree.LANGUAGE= FND_GLOBAL.Current_Language	
Where valAccout.Value = 
(Case 
When inline.PO_HEADER_ID is not null Then SUBSTR(glcodeordist.Segment2,1,3) 
Else SUBSTR(glcode.Segment2, 1,3) 
End) 
and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account') as AccountFirstThreeDesc,

Case 
When inline.PO_HEADER_ID is not null Then glcodeordist.Segment2 
Else glcode.Segment2 
End as Account,

Case 
When inline.PO_HEADER_ID is not null Then valAccoutNordist.Description 
Else valAccoutN.Description 
End as AccountDescription,

(Case 
When inline.PO_HEADER_ID is not null Then glcodeordist.Segment2 
Else glcode.Segment2 
End || ' - ' || 
Case 
When inline.PO_HEADER_ID is not null Then valAccoutNordist.Description 
Else valAccoutN.Description 
End) as AccountWideDesc,


inline.PJC_PROJECT_ID LineProjectId,
inline.PJC_ORGANIZATION_ID LineOrganizationId,

indist.PJC_PROJECT_ID as DistProjId,
indist.PJC_ORGANIZATION_ID as DistPrjOrgId,


-- Project
CASE
    WHEN inline.PJC_PROJECT_ID is not null THEN
		(Select 
			Distinct
			(
			Case 
			When vl.Segment1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
			When vl.Segment1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
			Else vl.Segment1
			End)
			From PJF_PROJECTS_ALL_VL vl
			Where inline.PJC_PROJECT_ID = vl.Project_ID)
	
	When indist.PJC_PROJECT_ID is not null Then
		(Select 
			Distinct
			(
			Case 
			When vl.Segment1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
			When vl.Segment1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
			Else vl.Segment1
			End)
			From PJF_PROJECTS_ALL_VL vl
			Where indist.PJC_PROJECT_ID = vl.Project_ID)
	When inline.ATTRIBUTE12 = 'OPRL.CMMN.0001' or indist.ATTRIBUTE12 = 'OPRL.CMMN.0001'  Then 'La Romana Common Expenses'
	When inline.ATTRIBUTE12 = 'INVT.LRMN.001' or indist.ATTRIBUTE12 = 'INVT.LRMN.001'  Then 'La Romana Common Expenses'
	Else SubPDesc.Description
	END as Project_Name,
	
	
-- Expenditure_Organization

	CASE
    WHEN inline.PJC_ORGANIZATION_ID is not null THEN
		(Select
			Distinct
			orge.Name
			From HR_ORGANIZATION_UNITS_F_TL orge
			Where orge.Language = 'US' and (Trunc(SysDate) between orge.EFFECTIVE_START_DATE and orge.EFFECTIVE_END_DATE)
			and orge.ORGANIZATION_ID = inline.PJC_ORGANIZATION_ID)
	ELSE
		(Select
			Distinct
			orgE.Name
			From
			HR_ORGANIZATION_UNITS_F_TL orge
			Where orge.Language = 'US' and (Trunc(SysDate) between orge.EFFECTIVE_START_DATE and orge.EFFECTIVE_END_DATE)
			and orge.ORGANIZATION_ID = indist.PJC_ORGANIZATION_ID)
	END as Expenditure_Organization,


-- BusinessFunction (CostCategory) --------------------------------------------
  
   CASE
   When inhead.Invoice_Type_Lookup_Code = 'PREPAYMENT' Then 'Prepayment'
   WHEN inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'TAX' Then 'Tax'
   WHEN inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'PREPAY' Then 'Prepayment'
   WHEN inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'AWT' Then 'WitholdingTax'
   Else CostCatDesc.DESCRIPTION 
   End as BusinessFunction,
 	
-- Main Project--------------------------------------------
	
	MainPDesc.Description as Main_Project,
	
-- Sub Project--------------------------------------------
   
   SubPDesc.Description as Sub_Project,

-- Process Type --------------------------------------------
	
	ProcessDesc.Description as ProcessType,
	
-- Member Type --------------------------------------------

	MemberTypeDesc.DESCRIPTION as Member_Type,

-- Member --------------------------------------------

	MemberDesc.DESCRIPTION as Member,

-- Place --------------------------------------------

	PlaceDesc.DESCRIPTION as Place,


indist.LINE_TYPE_LOOKUP_CODE as InDistLineType,

indist.Amount as DistAmountInvoiceCurrency,

inhead.Invoice_Currency_Code as InvoiceCurrency,

Case 
When inhead.EXCHANGE_RATE is null Then 1
Else inhead.EXCHANGE_RATE 
End as InvoiceExchangeRate,

indist.Amount * 
(Case 
When inhead.EXCHANGE_RATE is null Then 1
Else inhead.EXCHANGE_RATE 
End) as DistAmountLedgerCurrency, 

(Select
inheadx.Invoice_Currency_Code
From AP_Invoices_All inheadx
Where rownum <= 1 and inheadx.EXCHANGE_RATE is null and inhead.ORG_ID = inheadx.ORG_ID)
as LedgerCurrency,

CASE
When inhead.Invoice_Currency_Code = 'USD' Then 1
Else TRUNC(drate.Conversion_Rate,4) 
End as DailyRateUSD,

CASE
When inhead.Invoice_Currency_Code = 'USD' Then indist.Amount
Else Trunc(indist.Amount / TRUNC(drate.Conversion_Rate,4), 4) 
End as DistAmountUSD,



-- Case
-- When inhead.Payment_Currency_Code = 'USD' Then inhead.PAY_CURR_INVOICE_AMOUNT
-- Else TRUNC(inhead.PAY_CURR_INVOICE_AMOUNT / TRUNC(drate.Conversion_Rate,4),2) 
-- End as InvoiceAmountPaymentCurrency,


TO_CHAR(inhead.INVOICE_DATE, 'YYYY, MONTH') as InvoiceMonth,

inline.Accounting_Date,
inhead.EXCHANGE_Date as InvoiceExchangeDate,
inhead.CREATION_DATE as InvoiceCreationDate,
inhead.INVOICE_DATE as InvoiceDate
From 
AP_INVOICE_LINES_ALL inline
INNER JOIN AP_INVOICES_ALL inhead 
	Inner Join POZ_SUPPLIERS_V sup 
	On sup.VENDOR_ID = inhead.VENDOR_ID
	Inner Join POZ_SUPPLIER_SITES_V supsite
	On supsite.VENDOR_SITE_ID = inhead.VENDOR_SITE_ID
	Inner Join AP_TERMS_TL term 
	ON term.TERM_ID = inhead.TERMS_ID And term.LANGUAGE = fnd_Global.Current_Language
	Inner Join XLE_ENTITY_PROFILES ent 
	On ent.LEGAL_ENTITY_ID = inhead.LEGAL_ENTITY_ID
	Inner Join hr_organization_units horg
    ON horg.Organization_Id = inhead.Org_Id
	Left Join gl_daily_rates drate            
	ON drate.From_Currency = 'USD' and drate.TO_Currency = inhead.Invoice_Currency_Code
	And drate.Conversion_Type = 'Corporate' 
	and drate.CONVERSION_DATE = inhead.Invoice_Date
On inhead.INVOICE_ID = inline.INVOICE_ID and inhead.Invoice_Type_Lookup_Code <> 'PAYMENT REQUEST'
Inner Join AP_INVOICE_DISTRIBUTIONS_ALL indist 
			Inner Join GL_CODE_COMBINATIONS glcode 
				Inner Join FND_VS_VALUES_B valAccout
					Inner Join FND_VS_VALUES_TL valAccoutN 
					ON valAccout.Value_Id = valAccoutN.Value_Id 
					and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language	
				ON valAccout.Value = glcode.Segment2 and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
			ON indist.DIST_CODE_COMBINATION_ID  = glcode.CODE_COMBINATION_ID	
ON indist.INVOICE_ID = inline.Invoice_Id and  indist.INVOICE_LINE_NUMBER = inline.LINE_NUMBER and indist.LINE_TYPE_LOOKUP_CODE <> 'NONREC_TAX'
Left Join PO_LINES_ALL orderline 
		Inner Join PO_HEADERS_ALL orderhead 
		On orderline.PO_HEADER_Id = orderhead.PO_HEADER_Id
		INNER Join PO_DISTRIBUTIONS_ALL orderdist
			Inner Join GL_CODE_COMBINATIONS glcodeordist 
				Inner Join FND_VS_VALUES_B valAccoutordist
					Inner Join FND_VS_VALUES_TL valAccoutNordist
					ON valAccoutordist.Value_Id = valAccoutNordist.Value_Id 
					and valAccoutNordist.LANGUAGE = FND_GLOBAL.Current_Language
				ON valAccoutordist.Value = glcodeordist.Segment2 and valAccoutordist.ATTRIBUTE_CATEGORY = 'ACM_Account'
			ON orderdist.CODE_COMBINATION_ID  = glcodeordist.CODE_COMBINATION_ID
		ON orderdist.PO_LINE_ID = orderline.PO_LINE_ID
On inline.PO_LINE_ID = orderline.PO_LINE_ID 
	
-- (BusinessFunction) Cost Category Left Join
Left Join FND_VS_VALUES_B CostCatValue
	Inner Join FND_VS_VALUES_TL CostCatDesc
	ON CostCatValue.VALUE_ID = CostCatDesc.VALUE_ID
	and CostCatDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE1 is not null Then f_inline.ATTRIBUTE1
			Else f_indist.ATTRIBUTE1
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE1 is not null or f_indist.ATTRIBUTE1 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = CostCatValue.Value
and CostCatValue.ATTRIBUTE_CATEGORY = 'ACM_Business_Function_VS'

-- Main Project Left Join
Left Join FND_VS_VALUES_B MainPValue
	Inner Join FND_VS_VALUES_TL MainPDesc
	ON MainPValue.VALUE_ID = MainPDesc.VALUE_ID
	and MainPDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE11 is not null Then f_inline.ATTRIBUTE11
			Else f_indist.ATTRIBUTE11
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE11 is not null or f_indist.ATTRIBUTE11 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = MainPValue.Value
and MainPValue.ATTRIBUTE_CATEGORY = 'ACM_Project_VS_2'

-- Sub Project Left Join
Left Join FND_VS_VALUES_B SubPValue
	Inner Join FND_VS_VALUES_TL SubPDesc
	ON SubPValue.VALUE_ID = SubPDesc.VALUE_ID
	and SubPDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE12 is not null Then f_inline.ATTRIBUTE12
			Else f_indist.ATTRIBUTE12
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE12 is not null or f_indist.ATTRIBUTE12 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = SubPValue.Value
	AND 
	(SELECT 
		Case 
			When f_inline.ATTRIBUTE11 is not null Then f_inline.ATTRIBUTE11
			Else f_indist.ATTRIBUTE11
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE11 is not null or f_indist.ATTRIBUTE11 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = SubPValue.INDEPENDENT_VALUE
and SubPValue.ATTRIBUTE_CATEGORY = 'ACM_SubProject_VS'
			
-- Process Type Left Join
Left Join FND_VS_VALUES_B ProcessValue
	Inner Join FND_VS_VALUES_TL ProcessDesc
	ON ProcessValue.VALUE_ID = ProcessDesc.VALUE_ID
	and ProcessDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE13 is not null Then f_inline.ATTRIBUTE13
			Else f_indist.ATTRIBUTE13
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE13 is not null or f_indist.ATTRIBUTE13 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = ProcessValue.Value
and ProcessValue.ATTRIBUTE_CATEGORY = 'ACM_ProcessType_VS'			
			
-- Member Type Left Join
Left Join FND_VS_VALUES_B MemberTypeValue
	Inner Join FND_VS_VALUES_TL MemberTypeDesc
	ON MemberTypeValue.VALUE_ID = MemberTypeDesc.VALUE_ID
	and MemberTypeDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE6 is not null Then f_inline.ATTRIBUTE6
			Else f_indist.ATTRIBUTE6
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE6 is not null or f_indist.ATTRIBUTE6 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = MemberTypeValue.Value
and MemberTypeValue.ATTRIBUTE_CATEGORY = 'ACM_Member_Type_VS'				
			
-- Member Left Join
Left Join FND_VS_VALUES_B MemberValue
	Inner Join FND_VS_VALUES_TL MemberDesc
	ON MemberValue.VALUE_ID = MemberDesc.VALUE_ID
	and MemberDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE7 is not null Then f_inline.ATTRIBUTE7
			Else f_indist.ATTRIBUTE7
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE7 is not null or f_indist.ATTRIBUTE7 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = MemberValue.Value
	AND 
	(SELECT 
		Case 
			When f_inline.ATTRIBUTE6 is not null Then f_inline.ATTRIBUTE6
			Else f_indist.ATTRIBUTE6
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE6 is not null or f_indist.ATTRIBUTE6 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = MemberValue.INDEPENDENT_VALUE
and MemberValue.ATTRIBUTE_CATEGORY = 'ACM_Member_VS'			
	
-- Place Left Join
Left Join FND_VS_VALUES_B PlaceValue
	Inner Join FND_VS_VALUES_TL PlaceDesc
	ON PlaceValue.VALUE_ID = PlaceDesc.VALUE_ID
	and PlaceDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE8 is not null Then f_inline.ATTRIBUTE8
			Else f_indist.ATTRIBUTE8
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE8 is not null or f_indist.ATTRIBUTE8 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = PlaceValue.Value
and PlaceValue.ATTRIBUTE_CATEGORY = 'ACM_Place_VS'
			
			
Where

inhead.CANCELLED_DATE is null
AND inhead.Invoice_Date between (:PeriodStartDate) and  (:PeriodEndDate)
and inline.CANCELLED_FLAG = 'N'
and horg.Name IN (:CompanyBU)
Order By
inhead.INVOICE_DATE DESC,
inline.Invoice_Id,
inline.Line_Number
) FromInvoices

UNION All

-- Cash Advance - Expense
Select 
FromExpCash.*
From 
(
SELECT
Distinct
inhead.ORG_ID as OrgId,
horg.Name as BusinessUnit,

inline.Invoice_Id,
inhead.INVOICE_NUM as InvoiceNumber,

inhead.Invoice_Type_Lookup_Code as InvoiceType,

Translate(inhead.Description, chr(10)||chr(11)||chr(13), '   ') as InvoiceDescription,

inhead.PAID_ON_BEHALF_EMPLOYEE_ID as SupplierId,
Null as SupplierSiteId,

perf.Display_Name as Employee,
'EMPLOYEE' as VendorType,
inhead.EMPLOYEE_ADDRESS_CODE as SuppSiteName,

inhead.Terms_Id,
term.Name as Term_Name,

inline.Line_Type_Lookup_Code as InvoiceLineType,
inline.Line_Number as InvoiceLineNumber,
inline.Line_Source as LineSource,


inline.PO_HEADER_ID,
inline.PO_LINE_ID,


indist.DIST_CODE_COMBINATION_ID  as CodeId,

SUBSTR(glcode.Segment2, 1,3) as AccountFirstThree,

SUBSTR(glcode.Segment2, 1,3) || ' - ' ||
(Select
firstthree.Description
From FND_VS_VALUES_B valAccout
    Inner Join FND_VS_VALUES_TL firstthree 
    ON valAccout.Value_Id = firstthree.Value_Id 
    and firstthree.LANGUAGE= FND_GLOBAL.Current_Language	
Where valAccout.Value = SUBSTR(glcode.Segment2, 1,3)  
and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account') as AccountFirstThreeDesc,

glcode.Segment2 as Account,

valAccoutN.Description as AccountDescription,

glcode.Segment2 || ' - ' || valAccoutN.Description as AccountWideDesc,


inline.PJC_PROJECT_ID LineProjectId,
inline.PJC_ORGANIZATION_ID LineOrganizationId,

indist.PJC_PROJECT_ID as DistProjId,
indist.PJC_ORGANIZATION_ID as DistPrjOrgId,


-- Project
CASE
    WHEN inline.PJC_PROJECT_ID is not null THEN
		(Select 
			Distinct
			(
			Case 
			When vl.Segment1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
			When vl.Segment1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
			Else vl.Segment1
			End)
			From PJF_PROJECTS_ALL_VL vl
			Where inline.PJC_PROJECT_ID = vl.Project_ID)
	
	When indist.PJC_PROJECT_ID is not null Then
		(Select 
			Distinct
			(
			Case 
			When vl.Segment1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
			When vl.Segment1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
			Else vl.Segment1
			End)
			From PJF_PROJECTS_ALL_VL vl
			Where indist.PJC_PROJECT_ID = vl.Project_ID)
	When inline.ATTRIBUTE12 = 'OPRL.CMMN.0001' or indist.ATTRIBUTE12 = 'OPRL.CMMN.0001'  Then 'La Romana Common Expenses'
	When inline.ATTRIBUTE12 = 'INVT.LRMN.001' or indist.ATTRIBUTE12 = 'INVT.LRMN.001'  Then 'La Romana Common Expenses'
	Else SubPDesc.Description
	END as Project_Name,
	
	
-- Expenditure_Organization

	CASE
    WHEN inline.PJC_ORGANIZATION_ID is not null THEN
		(Select
			Distinct
			orge.Name
			From HR_ORGANIZATION_UNITS_F_TL orge
			Where orge.Language = 'US' and (Trunc(SysDate) between orge.EFFECTIVE_START_DATE and orge.EFFECTIVE_END_DATE)
			and orge.ORGANIZATION_ID = inline.PJC_ORGANIZATION_ID)
	ELSE
		(Select
			Distinct
			orgE.Name
			From
			HR_ORGANIZATION_UNITS_F_TL orge
			Where orge.Language = 'US' and (Trunc(SysDate) between orge.EFFECTIVE_START_DATE and orge.EFFECTIVE_END_DATE)
			and orge.ORGANIZATION_ID = indist.PJC_ORGANIZATION_ID)
	END as Expenditure_Organization,


-- BusinessFunction (CostCategory) --------------------------------------------
  
   CASE
   When inhead.Invoice_Type_Lookup_Code = 'PREPAYMENT' Then 'Prepayment'
   WHEN inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'TAX' Then 'Tax'
   WHEN inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'PREPAY' Then 'Prepayment'
   WHEN inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'AWT' Then 'WitholdingTax'
   Else CostCatDesc.DESCRIPTION 
   End as BusinessFunction,
 	
-- Main Project--------------------------------------------
	
	MainPDesc.Description as Main_Project,
	
-- Sub Project--------------------------------------------
   
   SubPDesc.Description as Sub_Project,

-- Process Type --------------------------------------------
	
	ProcessDesc.Description as ProcessType,
	
-- Member Type --------------------------------------------

	MemberTypeDesc.DESCRIPTION as Member_Type,

-- Member --------------------------------------------

	MemberDesc.DESCRIPTION as Member,

-- Place --------------------------------------------

	PlaceDesc.DESCRIPTION as Place,


indist.LINE_TYPE_LOOKUP_CODE as InDistLineType,

indist.Amount as DistAmountInvoiceCurrency,

inhead.Invoice_Currency_Code as InvoiceCurrency,

Case 
When inhead.EXCHANGE_RATE is null Then 1
Else inhead.EXCHANGE_RATE 
End as InvoiceExchangeRate,

indist.Amount * 
(Case 
When inhead.EXCHANGE_RATE is null Then 1
Else inhead.EXCHANGE_RATE 
End) as DistAmountLedgerCurrency, 

(Select
inheadx.Invoice_Currency_Code
From AP_Invoices_All inheadx
Where rownum <= 1 and inheadx.EXCHANGE_RATE is null and inhead.ORG_ID = inheadx.ORG_ID)
as LedgerCurrency,

CASE
When inhead.Invoice_Currency_Code = 'USD' Then 1
Else TRUNC(drate.Conversion_Rate,4) 
End as DailyRateUSD,

CASE
When inhead.Invoice_Currency_Code = 'USD' Then indist.Amount
Else Trunc(indist.Amount / TRUNC(drate.Conversion_Rate,4), 4) 
End as DistAmountUSD,



-- Case
-- When inhead.Payment_Currency_Code = 'USD' Then inhead.PAY_CURR_INVOICE_AMOUNT
-- Else TRUNC(inhead.PAY_CURR_INVOICE_AMOUNT / TRUNC(drate.Conversion_Rate,4),2) 
-- End as InvoiceAmountPaymentCurrency,


TO_CHAR(inhead.INVOICE_DATE, 'YYYY, MONTH') as InvoiceMonth,

inline.Accounting_Date,
inhead.EXCHANGE_Date as InvoiceExchangeDate,
inhead.CREATION_DATE as InvoiceCreationDate,
inhead.INVOICE_DATE as InvoiceDate
From 
AP_INVOICE_LINES_ALL inline
INNER JOIN AP_INVOICES_ALL inhead
	Inner Join PER_PERSON_NAMES_F perf 
    ON inhead.PAID_ON_BEHALF_EMPLOYEE_ID = perf.PERSON_ID and perf.Name_Type = 'GLOBAL' and Trunc(Sysdate) between perf.EFFECTIVE_START_DATE and perf.EFFECTIVE_End_DATE 
	Inner Join AP_TERMS_TL term 
	ON term.TERM_ID = inhead.TERMS_ID And term.LANGUAGE = fnd_Global.Current_Language
	Inner Join XLE_ENTITY_PROFILES ent 
	On ent.LEGAL_ENTITY_ID = inhead.LEGAL_ENTITY_ID
	Inner Join hr_organization_units horg
    ON horg.Organization_Id = inhead.Org_Id
	Left Join gl_daily_rates drate            
	ON drate.From_Currency = 'USD' and drate.TO_Currency = inhead.Invoice_Currency_Code
	And drate.Conversion_Type = 'Corporate' 
	and drate.CONVERSION_DATE = inhead.Invoice_Date
On inhead.INVOICE_ID = inline.INVOICE_ID and inhead.Invoice_Type_Lookup_Code = 'PAYMENT REQUEST'
Inner Join AP_INVOICE_DISTRIBUTIONS_ALL indist 
			Inner Join GL_CODE_COMBINATIONS glcode 
				Inner Join FND_VS_VALUES_B valAccout
					Inner Join FND_VS_VALUES_TL valAccoutN 
					ON valAccout.Value_Id = valAccoutN.Value_Id 
					and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language	
				ON valAccout.Value = glcode.Segment2 and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
			ON indist.DIST_CODE_COMBINATION_ID  = glcode.CODE_COMBINATION_ID	
ON indist.INVOICE_ID = inline.Invoice_Id and  indist.INVOICE_LINE_NUMBER = inline.LINE_NUMBER and indist.LINE_TYPE_LOOKUP_CODE <> 'NONREC_TAX'

-- (BusinessFunction) Cost Category Left Join
Left Join FND_VS_VALUES_B CostCatValue
	Inner Join FND_VS_VALUES_TL CostCatDesc
	ON CostCatValue.VALUE_ID = CostCatDesc.VALUE_ID
	and CostCatDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE1 is not null Then f_inline.ATTRIBUTE1
			Else f_indist.ATTRIBUTE1
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE1 is not null or f_indist.ATTRIBUTE1 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = CostCatValue.Value
and CostCatValue.ATTRIBUTE_CATEGORY = 'ACM_Business_Function_VS'

-- Main Project Left Join
Left Join FND_VS_VALUES_B MainPValue
	Inner Join FND_VS_VALUES_TL MainPDesc
	ON MainPValue.VALUE_ID = MainPDesc.VALUE_ID
	and MainPDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE11 is not null Then f_inline.ATTRIBUTE11
			Else f_indist.ATTRIBUTE11
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE11 is not null or f_indist.ATTRIBUTE11 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = MainPValue.Value
and MainPValue.ATTRIBUTE_CATEGORY = 'ACM_Project_VS_2'

-- Sub Project Left Join
Left Join FND_VS_VALUES_B SubPValue
	Inner Join FND_VS_VALUES_TL SubPDesc
	ON SubPValue.VALUE_ID = SubPDesc.VALUE_ID
	and SubPDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE12 is not null Then f_inline.ATTRIBUTE12
			Else f_indist.ATTRIBUTE12
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE12 is not null or f_indist.ATTRIBUTE12 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = SubPValue.Value
	AND 
	(SELECT 
		Case 
			When f_inline.ATTRIBUTE11 is not null Then f_inline.ATTRIBUTE11
			Else f_indist.ATTRIBUTE11
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE11 is not null or f_indist.ATTRIBUTE11 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = SubPValue.INDEPENDENT_VALUE
and SubPValue.ATTRIBUTE_CATEGORY = 'ACM_SubProject_VS'
			
-- Process Type Left Join
Left Join FND_VS_VALUES_B ProcessValue
	Inner Join FND_VS_VALUES_TL ProcessDesc
	ON ProcessValue.VALUE_ID = ProcessDesc.VALUE_ID
	and ProcessDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE13 is not null Then f_inline.ATTRIBUTE13
			Else f_indist.ATTRIBUTE13
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE13 is not null or f_indist.ATTRIBUTE13 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = ProcessValue.Value
and ProcessValue.ATTRIBUTE_CATEGORY = 'ACM_ProcessType_VS'			
			
-- Member Type Left Join
Left Join FND_VS_VALUES_B MemberTypeValue
	Inner Join FND_VS_VALUES_TL MemberTypeDesc
	ON MemberTypeValue.VALUE_ID = MemberTypeDesc.VALUE_ID
	and MemberTypeDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE6 is not null Then f_inline.ATTRIBUTE6
			Else f_indist.ATTRIBUTE6
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE6 is not null or f_indist.ATTRIBUTE6 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = MemberTypeValue.Value
and MemberTypeValue.ATTRIBUTE_CATEGORY = 'ACM_Member_Type_VS'				
			
-- Member Left Join
Left Join FND_VS_VALUES_B MemberValue
	Inner Join FND_VS_VALUES_TL MemberDesc
	ON MemberValue.VALUE_ID = MemberDesc.VALUE_ID
	and MemberDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE7 is not null Then f_inline.ATTRIBUTE7
			Else f_indist.ATTRIBUTE7
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE7 is not null or f_indist.ATTRIBUTE7 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = MemberValue.Value
	AND 
	(SELECT 
		Case 
			When f_inline.ATTRIBUTE6 is not null Then f_inline.ATTRIBUTE6
			Else f_indist.ATTRIBUTE6
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE6 is not null or f_indist.ATTRIBUTE6 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = MemberValue.INDEPENDENT_VALUE
and MemberValue.ATTRIBUTE_CATEGORY = 'ACM_Member_VS'			
	
-- Place Left Join
Left Join FND_VS_VALUES_B PlaceValue
	Inner Join FND_VS_VALUES_TL PlaceDesc
	ON PlaceValue.VALUE_ID = PlaceDesc.VALUE_ID
	and PlaceDesc.LANGUAGE = fnd_Global.Current_Language
ON (SELECT 
		Case 
			When f_inline.ATTRIBUTE8 is not null Then f_inline.ATTRIBUTE8
			Else f_indist.ATTRIBUTE8
		End as Attribute
	From AP_INVOICE_LINES_ALL f_inline
		Inner join AP_INVOICE_DISTRIBUTIONS_ALL f_indist 
		ON f_indist.INVOICE_ID = f_inline.Invoice_Id 
		and f_indist.INVOICE_LINE_NUMBER = f_inline.LINE_NUMBER 
	Where (f_inline.ATTRIBUTE8 is not null or f_indist.ATTRIBUTE8 is not null) 
	and ROWNUM = 1 
	and f_inline.INVOICE_ID = inline.INVOICE_ID 
	and f_inline.LINE_NUMBER = inline.LINE_NUMBER
	) = PlaceValue.Value
and PlaceValue.ATTRIBUTE_CATEGORY = 'ACM_Place_VS'
			
			
Where

inhead.CANCELLED_DATE is null
AND inhead.Invoice_Date between (:PeriodStartDate) and  (:PeriodEndDate)
and inline.CANCELLED_FLAG = 'N'
and horg.Name IN (:CompanyBU)
Order By
inhead.INVOICE_DATE DESC,
inline.Invoice_Id,
inline.Line_Number
) FromExpCash



-- @GoktepeEren -- DarkNightX