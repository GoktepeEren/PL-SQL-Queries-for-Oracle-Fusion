-- New Invoice Line
-- Edited
Select 
FromInvoices.*
From 
(
SELECT
Distinct
'FromInvoices' as TableType,
inhead.ORG_ID as OrgId,
horg.Name as BusinessUnit,

inline.Invoice_Id,
inhead.INVOICE_NUM as InvoiceNumber,

inhead.Invoice_Type_Lookup_Code as InvoiceType,
Translate(inhead.Description, chr(10)||chr(11)||chr(13), '   ') as InvoiceDescription,

inhead.VENDOR_ID as SupplierId,
inhead.VENDOR_SITE_ID as SupplierSiteId,
sup.VENDOR_NAME as SuppName,
supsite.PARTY_SITE_NAME as SuppSiteName,

inhead.Terms_Id,
term.Name as Term_Name,

inline.Line_Type_Lookup_Code as InvoiceLineType,
inline.Line_Number as InvoiceLineNumber,
inline.Line_Source as LineSource,


inline.PO_HEADER_ID,
inline.PO_LINE_ID,

orderhead.Segment1 as OrderNumber,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderhead.DOCUMENT_STATUS 
Else ''
End as OrderDocumentStatus,

orderline.LINE_NUM as OrderLineNumber,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderline.LINE_STATUS 
Else '' 
End as OrderLineStatus,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderline.ATTRIBUTE1 
Else ''
End as OrderLineType,

inline.INVENTORY_ITEM_ID,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then Translate(inline.ITEM_DESCRIPTION , chr(10)||chr(11)||chr(13), '   ')  
Else ''
End as InventoryItemName,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then Translate(orderline.ITEM_DESCRIPTION , chr(10)||chr(11)||chr(13), '   ')  
Else ''
End as OrderlineDesc,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then Translate(inline.Description, chr(10)||chr(11)||chr(13), '   ') 
Else ''
End as InvoiceLineDescription,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderdist.DELIVER_TO_LOCATION_ID 
Else To_Number('')
End as OrderLineDeliverToLoc,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then inline.Purchasing_Category_Id
Else To_Number('')
End as PurchasingCategoryId,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderline.CATEGORY_ID 
Else To_Number('')
End as OrderLineCategory,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then cate.Category_Name
Else ''
End as Category_Name,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderline.DISCOUNT 
Else To_Number('')
End as OrderLineDiscount,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderline.UOM_CODE 
Else '' 
End as OrderLineMeaCode,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderline.Quantity 
Else To_Number('')
End as OrderLineQuantity,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderdist.QUANTITY_ORDERED
Else To_Number('')
End AS OrderLiQuantityOrdered,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderdist.QUANTITY_DELIVERED 
Else To_Number('')
End AS OrderLiQuantityDelivered,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderdist.QUANTITY_BILLED 
Else To_Number('')
End AS OrderLiQuantityBilled,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderdist.QUANTITY_CANCELLED 
Else To_Number('')
End AS OrderLiQuantityCanceled,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderline.LIST_PRICE 
Else To_Number('')
End as OrderLineListPrice,

-- Case 
-- WHEN orderhead.CURRENCY_CODE = 'USD' Then orderline.LIST_PRICE
-- Else Trunc(orderline.LIST_PRICE / TRUNC(drate.Conversion_Rate,2), 2)
-- End OrderLineListPriceUSD,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then orderline.Unit_PRICE 
Else To_Number('')
End as OrderLineUnitPrice,

-- Case 
-- WHEN orderhead.CURRENCY_CODE = 'USD' Then orderline.Unit_PRICE 
-- Else Trunc(orderline.Unit_PRICE  / TRUNC(drate.Conversion_Rate,2), 2)
-- End OrderLineUnitPriceUSD,

-- Trunc(orderdist.RECOVERABLE_TAX,2) as OrderLineExcTax,

-- Case 
-- WHEN orderhead.CURRENCY_CODE = 'USD' Then Trunc(orderdist.RECOVERABLE_TAX,2)
-- Else Trunc(Trunc(orderdist.RECOVERABLE_TAX,2) / TRUNC(drate.Conversion_Rate,2), 2)
-- End OrderLineExcTaxUSD,


-- Trunc(orderdist.RECOVERABLE_INCLUSIVE_TAX,2) as OrderLineIncTax,

-- Case 
-- WHEN orderhead.CURRENCY_CODE = 'USD' Then Trunc(orderdist.RECOVERABLE_INCLUSIVE_TAX,2)
-- Else Trunc(Trunc(orderdist.RECOVERABLE_INCLUSIVE_TAX,2) / TRUNC(drate.Conversion_Rate,2), 2)
-- End OrderLineIncTaxUSD,

-- Trunc(orderdist.TAX_EXCLUSIVE_AMOUNT,2) as OrderLineWoutTaxAmount,

-- Case 
-- WHEN orderhead.CURRENCY_CODE = 'USD' Then Trunc(orderdist.TAX_EXCLUSIVE_AMOUNT,2)
-- Else Trunc(Trunc(orderdist.TAX_EXCLUSIVE_AMOUNT,2) / TRUNC(drate.Conversion_Rate,2), 2)
-- End OrderLineWoutTaxAmountUSD,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then Trunc((orderdist.RECOVERABLE_INCLUSIVE_TAX + orderdist.RECOVERABLE_TAX + orderdist.TAX_EXCLUSIVE_AMOUNT),2)
Else To_Number('')
End as OrderLineAmountWTax,

CASE
When (indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' Or indist.LINE_TYPE_LOOKUP_CODE = 'ITEM' ) Then  
	Case 
	WHEN orderhead.CURRENCY_CODE = 'USD' Then Trunc((orderdist.RECOVERABLE_INCLUSIVE_TAX + orderdist.RECOVERABLE_TAX + orderdist.TAX_EXCLUSIVE_AMOUNT),2)
	Else Trunc(Trunc((orderdist.RECOVERABLE_INCLUSIVE_TAX + orderdist.RECOVERABLE_TAX + orderdist.TAX_EXCLUSIVE_AMOUNT),2) / TRUNC(drate.Conversion_Rate,2), 2)
	End 
Else TO_NUMBER('') 
End as OrderLineAmountWTaxUSD,


orderhead.AGENT_ID	as Buyer,

inline.PREPAY_INVOICE_ID as PrepayInvoicedId,
prehead.Invoice_Num as LinkedPrepayment,
inline.PREPAY_LINE_NUMBER as PrepayLineNumber,

Case 
When inline.Tax_Rate_Code is null Then inline.Tax_Classification_Code
else inline.Tax_Rate_Code
End as TaxRateCode,

inline.Tax_Rate,


Case 
When inline.PO_HEADER_ID is not null Then orderdist.CODE_COMBINATION_ID 
Else indist.DIST_CODE_COMBINATION_ID 
End as CodeId,

Case 
When inline.PO_HEADER_ID is not null Then glcodeordist.Segment2 
Else glcode.Segment2 
End as Account,

Case 
When inline.PO_HEADER_ID is not null Then valAccoutNordist.Description 
Else valAccoutN.Description 
End as AccountDescription,

(Case 
When inline.PO_HEADER_ID is not null Then valAccoutNordist.Description 
Else valAccoutN.Description 
End || ' - ' || 
Case 
When inline.PO_HEADER_ID is not null Then glcodeordist.Segment2 
Else glcode.Segment2 
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
			Where orge.Language = 'US' 
			and orge.ORGANIZATION_ID = inline.PJC_ORGANIZATION_ID)
	ELSE
		(Select
			Distinct
			orgE.Name
			From
			HR_ORGANIZATION_UNITS_F_TL orge
			Where orge.Language = 'US'
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

CASE
When inhead.Invoice_Currency_Code = 'USD' Then indist.Amount
Else Trunc(indist.Amount / TRUNC(drate.Conversion_Rate,2), 2) 
End as DistAmountUSD,


-- inline.Amount as LineAmountInvoiceCurrency,

-- CASE
-- When inhead.Invoice_Currency_Code = 'USD' Then inline.Amount
-- Else Trunc(inline.Amount / TRUNC(drate.Conversion_Rate,2), 2) 
-- End as LineAmountUSD,


-- inhead.Invoice_Amount as InvoiceAmount,

-- CASE
-- When inhead.Invoice_Currency_Code = 'USD' Then inhead.Invoice_Amount 
-- Else Trunc(inhead.Invoice_Amount / TRUNC(drate.Conversion_Rate,2), 2) 
-- End as InvoiceAmountUSD,

-- inhead.TOTAL_TAX_AMOUNT as InvoiceTaxAmount,


-- CASE
-- When inhead.Invoice_Currency_Code = 'USD' Then inhead.TOTAL_TAX_AMOUNT
-- Else Trunc(inhead.TOTAL_TAX_AMOUNT / TRUNC(drate.Conversion_Rate,2), 2) 
-- End as InvoiceTaxAmountUSD,

-- (inhead.Invoice_Amount + inhead.TOTAL_TAX_AMOUNT) as InvoiceTotalAmount,

-- CASE
-- When inhead.Invoice_Currency_Code = 'USD' Then (inhead.Invoice_Amount + inhead.TOTAL_TAX_AMOUNT)
-- Else Trunc((inhead.Invoice_Amount + inhead.TOTAL_TAX_AMOUNT) / TRUNC(drate.Conversion_Rate,2) ,2)
-- End as InvoiceTotalAmountUSD,

inhead.EXCHANGE_RATE as InvoiceExchangeRate,

CASE
When inhead.Invoice_Currency_Code = 'USD' Then 1
Else TRUNC(drate.Conversion_Rate,2) 
End as DailyRateUSD,

inhead.Invoice_Currency_Code as InvoiceCurrency,

-- Case
-- When inhead.Payment_Currency_Code = 'USD' Then inhead.PAY_CURR_INVOICE_AMOUNT
-- Else TRUNC(inhead.PAY_CURR_INVOICE_AMOUNT / TRUNC(drate.Conversion_Rate,2),2) 
-- End as InvoiceAmountPaymentCurrency,

inhead.Payment_Currency_Code as PaymentCurrency,


Case
	When inhead.PAYMENT_STATUS_FLAG = 'P' Then 'Partial Paid' 
	When inhead.PAYMENT_STATUS_FLAG = 'Y' Then 'Paid' 
	When inhead.PAYMENT_STATUS_FLAG = 'N' Then 'Not Paid' 
End

as PaymentStatus,
	
Case 
When ((indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' OR indist.LINE_TYPE_LOOKUP_CODE = 'ITEM') And inline.Line_Number = 1) Then inhead.Amount_Paid 
Else TO_NUMBER('') 
End as PaidAmountInvoiceCurrency, 

Case 
	When ((indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' OR indist.LINE_TYPE_LOOKUP_CODE = 'ITEM') And inline.Line_Number = 1) Then
		CASE
		When inhead.Invoice_Currency_Code = 'USD' Then inhead.Amount_Paid
		Else TRUNC(inhead.Amount_Paid / TRUNC(drate.Conversion_Rate,2),2) 
		End 
Else TO_NUMBER('')
End	
	as PaidAmountUSD,


inhead.EXTERNAL_BANK_ACCOUNT_ID as BankAccountId,


orderline.ATTRIBUTE_DATE1 as OrderLineStartPeriodDate,
orderline.ATTRIBUTE_DATE2 as OrderLineEndPeriodDate,
orderhead.CREATION_DATE as OrderCreationDate,
orderhead.SUBMIT_DATE as OrderSubmitDate,
orderhead.APPROVED_DATE as OrderApprovedDate,
inhead.Terms_Date,
inline.Period_Name,
inline.Accounting_Date,
inhead.EXCHANGE_Date as InvoiceExchangeDate,
inhead.CREATION_DATE as InvoiceCreationDate,
TO_CHAR(inhead.INVOICE_DATE, 'YYYY, MONTH') as InvoiceDateMonth,
inhead.INVOICE_DATE as InvoiceDate,
inhead.CREATED_BY as InvoiceCreationBy,
prehead.INVOICE_DATE as LinkedPrepaymentDate,


inline.CANCELLED_FLAG as LineCanceled,
inhead.CANCELLED_DATE as InvoiceCanceledDate,
inhead.CANCELLED_AMOUNT as InvoiceCanceledAmount


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
On inhead.INVOICE_ID = inline.INVOICE_ID
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
Left join EGP_Categories_TL cate ON cate.Category_Id = inline.Purchasing_Category_Id and cate.LANGUAGE= FND_GLOBAL.Current_Language
Left Join AP_INVOICES_ALL prehead ON prehead.INVOICE_ID = inline.Prepay_Invoice_Id

	
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
AND 

-- **Getting invoices of March
-- (inhead.Invoice_Date between TO_DATE('01.03.2020', 'dd.MM.yyyy') and  TO_DATE('31.03.2020', 'dd.MM.yyyy'))
inhead.Invoice_Date between ((:PeriodStartDate)) and  (:PeriodEndDate)
and inline.CANCELLED_FLAG = 'N'
-- and inhead.Invoice_Date between TO_DATE('01.03.2020', 'dd.MM.yyyy') and  TO_DATE('31.03.2020', 'dd.MM.yyyy')
-- and (horg.Name like 'DO01%' or  horg.Name like 'DO02%')
and horg.Name IN (:CompanyBU)
Order By
inhead.INVOICE_DATE DESC,
inline.Invoice_Id,
inline.Line_Number
) FromInvoices

UNION ALL

Select
FromExtTransaciton.*
From 
(
Select
'FromExtTransaciton' as TableType,
exttra.BUSINESS_UNIT_ID as BusinessUnit,
horgext.Name as CompanyName,

exttra.EXTERNAL_TRANSACTION_ID as ExTransactionId,
To_Char(exttra.TRANSACTION_ID) as TransactionNumber,


Case exttra.TRANSACTION_TYPE
When 'ACH'		Then 'Automated clearing house'
When 'BKA' 		Then 'Bank adjustment'
When 'BKF' 		Then 'Fee'
When 'BNB'		Then 'Banka Belgesi'
When 'CHK'		Then 'Check'
When 'EFT'		Then 'Electronic funds transfer'
When 'INT'		Then 'Interest'
When 'KRK'		Then 'Credit Card'
When 'KTD'		Then 'Kasa Tediye'
When 'KTH'		Then 'Kasa Tahsil'
When 'LBX'		Then 'Lockbox'
When 'MSC'		Then 'Miscellaneous'
When 'ORA_REV'	Then 'Reversal'
When 'ZBA' 		Then 'Zero balancing'
Else '-'
End as TRANSACTIONType,

Translate(exttra.DESCRIPTION, chr(10)||chr(11)||chr(13), '   ')  as TransactionDesc,

Null as Supp,
Null as SuppSite,
'External Transactions' as SuppName,
Null as SuppSiteName,

Null as TermsId,
Null as TermName,

Null as TraType,
Null as LineNum,
exttra.SOURCE,

Null as orderid,
Null as orderlineid,

Null as ordernumber,

Case
When exttra.STATUS = 'UNR' Then 'Unreconciled'
When exttra.STATUS = 'UNR' Then 'Reconciled' 
ELSE ''
End as TransactionStatus,

Null as OrLineNumber,
Null as LineStatus,

Null as LineType,
Null as InvItemId,
Null as InvItemName,

Null as OrderLineDesc,
Null as InvoiceLineDescription,

Null as OrderLineDeliverToLoc,
Null as CatId,

Null as OrderLineCategory,
Null as Category_Name,
Null as OrderLineDiscount,
Null as OrderLineMeaCode			,
Null as OrderLineQuantity           ,
Null as OrderLiQuantityOrdered      ,

Null as OrderLiQuantityDelivered    ,
Null as OrderLiQuantityBilled       ,
Null as OrderLiQuantityCanceled     ,
Null as OrderLineListPrice          ,
Null as OrderLineUnitPrice          ,
Null as OrderLineAmountWTax         ,
Null as OrderLineAmountWTaxUSD      ,
Null as Buyer                       ,
Null as PrepayInvoicedId            ,
Null as LinkedPrepayment            ,
Null as PrepayLineNumber            ,
Null as TaxRateCode                 ,
Null as Tax_Rate                    ,


exttra.OFFSET_CCID as AccountId,
glcodeext.Segment2 as Account,
valAccoutNext.Description as AccountDescription,

(valAccoutNext.Description || ' - ' || glcodeext.Segment2) as AccountWideDesc,



Null as LineProjectId,
Null as LineOrganizationId,
Null as DistProjId,
Null as DistPrjOrgId,
Null as Project_Name,
Null as Expenditure_Organization,

Null as BusinessFunction,
Null as Main_Project,
Null as Sub_Project,
Null as ProcessType,
Null as Member_Type,
Null as Member,
Null as Place,

Null as InDistLineType,

exttra.AMOUNT as Amount,

CASE
When exttra.CURRENCY_CODE = 'USD' Then exttra.AMOUNT 
Else TRUNC(exttra.AMOUNT  / TRUNC(drateext.Conversion_Rate,2),2) 
End as AmountUsd,

Null as InvoiceExchangeRate,

Case 
WHEN exttra.CURRENCY_CODE = 'USD' Then 1
Else TRUNC(drateext.Conversion_Rate,2)
End as DailyRateUSD,

exttra.CURRENCY_CODE as TransCurrency,

Null as PaymentCurrency,
'Paid' as PaymentStatus,

exttra.AMOUNT as PaidAmount,

CASE
When exttra.CURRENCY_CODE = 'USD' Then exttra.AMOUNT 
Else TRUNC(exttra.AMOUNT  / TRUNC(drateext.Conversion_Rate,2),2) 
End as PaidAmountUsd,


exttra.Bank_Account_Id as BankAccountId,

Null as OrderLineStartPeriodDate,
Null as OrderLineEndPeriodDate,
Null as OrderCreationDate,
Null as OrderSubmitDate,
Null as OrderApprovedDate,
Null as Terms_Date,
Null as Period_Name,
Null as Accounting_Date,
Null as InvoiceExchangeDate,
exttra.CREATION_DATE as TraCreationDate,
TO_CHAR(exttra.TRANSACTION_DATE, 'YYYY, MONTH') as TransactionDateMonth,
exttra.TRANSACTION_DATE as TransactionDate,
Null as InvoiceCreationBy,
Null as LinkedPrepaymentDate,

Null as LineCanceled,
Null as InvoiceCanceledDate,
Null as InvoiceCanceledAmount

From 
CE_EXTERNAL_TRANSACTIONS exttra
	Inner Join GL_CODE_COMBINATIONS glcodeext
		Inner Join FND_VS_VALUES_B valAccoutext
			Inner Join FND_VS_VALUES_TL valAccoutNext 
			ON valAccoutext.Value_Id = valAccoutNext.Value_Id 
			and valAccoutNext.LANGUAGE= FND_GLOBAL.Current_Language
			
		ON valAccoutext.Value = glcodeext.Segment2 and valAccoutext.ATTRIBUTE_CATEGORY = 'ACM_Account'
	ON exttra.OFFSET_CCID  = glcodeext.CODE_COMBINATION_ID
	Inner Join hr_organization_units horgext
    ON horgext.Organization_Id = exttra.BUSINESS_UNIT_ID
	Left Join gl_daily_rates drateext            
	ON drateext.From_Currency = 'USD' and drateext.TO_Currency = exttra.CURRENCY_CODE
	And drateext.Conversion_Type = 'Corporate'
	and drateext.CONVERSION_DATE = exttra.TRANSACTION_DATE	
Where 
exttra.STATUS <> 'VOID'
and horgext.Name IN (:CompanyBU)
and (exttra.TRANSACTION_DATE between ((:PeriodStartDate)) and  (:PeriodEndDate))
Order By exttra.TRANSACTION_DATE Desc
) FromExtTransaciton

UNION ALL 

Select FromOrder.*
From 
(
-- New Invoice Line

SELECT
Distinct
'FromOrders' as TableType,
orheadex.BILLTO_BU_ID as OrgId,
horg.Name as BusinessUnit,

Null as Null2,
Null as Null3,

Null as Null4,
Null as Null5,

orheadex.VENDOR_ID as SupplierId,
orheadex.VENDOR_SITE_ID as SupplierSiteId,
sup.VENDOR_NAME as SuppName,
supsite.PARTY_SITE_NAME as SuppSiteName,

orheadex.Terms_Id,
term.Name as Term_Name,

Null as Null6,
Null as Null7,
Null as Null8,


orheadex.PO_HEADER_ID,
orLineex.PO_LINE_ID,

orheadex.Segment1 as OrderNumber,
orheadex.DOCUMENT_STATUS as OrderDocumentStatus,

orLineex.LINE_NUM as orLineexLineNumber,
orLineex.LINE_STATUS as orLineexStatus,
orLineex.ATTRIBUTE1 as orLineexType,

orLineex.ITEM_ID,
Null as InventoryItemName,
Translate(orLineex.ITEM_DESCRIPTION, chr(10)||chr(11)||chr(13), '   ')   as orLineexDesc,
Null as Null10,
orDistex.DELIVER_TO_LOCATION_ID as orLineexDeliverToLoc,
Null as Null11,
orLineex.CATEGORY_ID as orLineexCategory,
cate.Category_Name,

orLineex.DISCOUNT as orLineexDiscount,
orLineex.UOM_CODE as orLineexMeaCode,
orLineex.Quantity as orLineexQuantity,
orDistex.QUANTITY_ORDERED AS OrderLiQuantityOrdered,
orDistex.QUANTITY_DELIVERED AS OrderLiQuantityDelivered,
orDistex.QUANTITY_BILLED AS OrderLiQuantityBilled,
orDistex.QUANTITY_CANCELLED AS OrderLiQuantityCanceled,

orLineex.LIST_PRICE as orLineexListPrice,

-- Case 
-- WHEN orheadex.CURRENCY_CODE = 'USD' Then orLineex.LIST_PRICE
-- Else Trunc(orLineex.LIST_PRICE / TRUNC(dorderrate.Conversion_Rate,2), 2)
-- End orLineexListPriceUSD,

orLineex.Unit_PRICE as orLineexUnitPrice,

-- Case 
-- WHEN orheadex.CURRENCY_CODE = 'USD' Then orLineex.Unit_PRICE 
-- Else Trunc(orLineex.Unit_PRICE  / TRUNC(dorderrate.Conversion_Rate,2), 2)
-- End orLineexUnitPriceUSD,

-- Trunc(orDistex.RECOVERABLE_TAX,2) as orLineexExcTax,

-- Case 
-- WHEN orheadex.CURRENCY_CODE = 'USD' Then Trunc(orDistex.RECOVERABLE_TAX,2)
-- Else Trunc(Trunc(orDistex.RECOVERABLE_TAX,2) / TRUNC(dorderrate.Conversion_Rate,2), 2)
-- End orLineexExcTaxUSD,


-- Trunc(orDistex.RECOVERABLE_INCLUSIVE_TAX,2) as orLineexIncTax,

-- Case 
-- WHEN orheadex.CURRENCY_CODE = 'USD' Then Trunc(orDistex.RECOVERABLE_INCLUSIVE_TAX,2)
-- Else Trunc(Trunc(orDistex.RECOVERABLE_INCLUSIVE_TAX,2) / TRUNC(dorderrate.Conversion_Rate,2), 2)
-- End orLineexIncTaxUSD,

-- Trunc(orDistex.TAX_EXCLUSIVE_AMOUNT,2) as orLineexWoutTaxAmount,

-- Case 
-- WHEN orheadex.CURRENCY_CODE = 'USD' Then Trunc(orDistex.TAX_EXCLUSIVE_AMOUNT,2)
-- Else Trunc(Trunc(orDistex.TAX_EXCLUSIVE_AMOUNT,2) / TRUNC(dorderrate.Conversion_Rate,2), 2)
-- End orLineexWoutTaxAmountUSD,

Trunc((orDistex.RECOVERABLE_INCLUSIVE_TAX + orDistex.RECOVERABLE_TAX + orDistex.TAX_EXCLUSIVE_AMOUNT),2) as orLineexAmountWTax,

Case 
WHEN orheadex.CURRENCY_CODE = 'USD' Then Trunc((orDistex.RECOVERABLE_INCLUSIVE_TAX + orDistex.RECOVERABLE_TAX + orDistex.TAX_EXCLUSIVE_AMOUNT),2)
Else Trunc(Trunc((orDistex.RECOVERABLE_INCLUSIVE_TAX + orDistex.RECOVERABLE_TAX + orDistex.TAX_EXCLUSIVE_AMOUNT),2) / TRUNC(dorderrate.Conversion_Rate,2), 2)
End orLineexAmountWTaxUSD,


orheadex.AGENT_ID as Buyer,

Null as Null12,
Null as Null13,
Null as Null14,

Null as Null15,
Null as Null147,


orDistex.CODE_COMBINATION_ID CodeId,
glcode.Segment2 as Account,
valAccoutN.Description as AccountDescription,

(valAccoutN.Description || ' - ' || glcode.Segment2) as AccountWideDesc,


-- inline.PJC_PROJECT_ID LineProjectId,
Null as Null16,
-- inline.PJC_ORGANIZATION_ID LineOrganizationId,
Null as Null17,

orDistex.PJC_PROJECT_ID as DistProjId,
orDistex.PJC_ORGANIZATION_ID as DistPrjOrgId,


-- Project

CASE
    WHEN orDistex.PJC_PROJECT_ID is not null THEN
		(Select 
		Distinct
		(
			Case 
			When vl.Segment1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
			When vl.Segment1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
			Else vl.Segment1
			End
		)
		From PJF_PROJECTS_ALL_VL vl
		Where orDistex.PJC_PROJECT_ID = vl.Project_ID)
	When orDistex.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Common Expenses'
	When orDistex.ATTRIBUTE12 = 'INVT.LRMN.001'  Then 'La Romana Common Expenses'	
	ELSE SubPDesc.Description
End
as Project_Name,
			
	
-- Expenditure_Organization

(Select
Distinct
orge.Name
From HR_ORGANIZATION_UNITS_F_TL orge
Where orge.Language = fnd_Global.Current_Language
and orge.ORGANIZATION_ID = orDistex.PJC_ORGANIZATION_ID)
as Expenditure_Organization,		
	
-- BusinessFunction (CostCategory) --------------------------------------------
  
   CostCatDesc.DESCRIPTION as BusinessFunction,
 	
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


Null as Null48,

Trunc((orDistex.RECOVERABLE_INCLUSIVE_TAX + orDistex.RECOVERABLE_TAX + orDistex.TAX_EXCLUSIVE_AMOUNT),2)  as OrderDistAmount, -- InvoiceDistAmount

Case 
WHEN orheadex.CURRENCY_CODE = 'USD' Then Trunc((orDistex.RECOVERABLE_INCLUSIVE_TAX + orDistex.RECOVERABLE_TAX + orDistex.TAX_EXCLUSIVE_AMOUNT),2)
Else Trunc(Trunc((orDistex.RECOVERABLE_INCLUSIVE_TAX + orDistex.RECOVERABLE_TAX + orDistex.TAX_EXCLUSIVE_AMOUNT),2) / TRUNC(dorderrate.Conversion_Rate,2), 2)
End OrderDistAmountUSD, -- InvoiceDistAmountUSD

--Null as Null20InvoiceLine,

--Null as Null21InvoiceLineUSD, 

-- Null as Null22,

-- Null as Null23,

-- Null as Null24,

-- Null as Null25,

-- Null as Null26,

-- Null as Null27,

Null as Null29,

Case 
WHEN orheadex.CURRENCY_CODE = 'USD' Then 1
Else TRUNC(dorderrate.Conversion_Rate,2)
End as OrderRateUSD,

orheadex.CURRENCY_CODE,

-- Null as Null31, 

Null as Null32,

'Not Paid Need Link Invoice' as PaidStatus,
	
Null as Null34,  

Null as Null35,


Null as Null36,


orLineex.ATTRIBUTE_DATE1 as orLineexStartPeriodDate,
orLineex.ATTRIBUTE_DATE2 as orLineexEndPeriodDate,
orheadex.CREATION_DATE as OrderCreationDate,
orheadex.SUBMIT_DATE as OrderSubmitDate,
orheadex.APPROVED_DATE as OrderApprovedDate,
Null as Terms_Date,
Null as Period_Name,
Null as Accounting_Date,
Null as InvoiceExchangeDate,
Null as Null41,
TO_CHAR(orheadex.CREATION_DATE, 'YYYY, MONTH')  as OrderDateMonth,
Null as Null42,
Null as Null43,
Null as LinkedPrepaymentDate,


Null as Null44,
Null as Null45,
Null as Null46

From 
PO_LINES_ALL orLineex
INNER JOIN PO_HEADERS_ALL orheadex 
	Inner Join POZ_SUPPLIERS_V sup 
	On sup.VENDOR_ID = orheadex.VENDOR_ID
	Inner Join POZ_SUPPLIER_SITES_V supsite
	On supsite.VENDOR_SITE_ID = orheadex.VENDOR_SITE_ID
	Inner Join AP_TERMS_TL term 
	ON term.TERM_ID = orheadex.TERMS_ID And term.LANGUAGE = fnd_Global.Current_Language
	Inner Join hr_organization_units horg
    ON horg.Organization_Id = orheadex.BILLTO_BU_ID
	Left Join gl_daily_rates dorderrate            
	ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = orheadex.CURRENCY_CODE
	And dorderrate.Conversion_Type = 'Corporate' 
	and dorderrate.CONVERSION_DATE = To_Date(To_Char(orheadex.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
On orLineex.PO_HEADER_Id = orheadex.PO_HEADER_Id
Inner Join PO_DISTRIBUTIONS_ALL orDistex 
			Inner Join GL_CODE_COMBINATIONS glcode 
				Inner Join FND_VS_VALUES_B valAccout
					Inner Join FND_VS_VALUES_TL valAccoutN 
					ON valAccout.Value_Id = valAccoutN.Value_Id 
					and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language
				ON valAccout.Value = glcode.Segment2 and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
			ON orDistex.CODE_COMBINATION_ID  = glcode.CODE_COMBINATION_ID
ON orDistex.PO_LINE_ID = orLineex.PO_LINE_ID
Left join EGP_Categories_TL cate ON cate.Category_Id = orLineex.Category_Id and cate.LANGUAGE= FND_GLOBAL.Current_Language


-- (BusinessFunction) Cost Category Left Join
Left Join FND_VS_VALUES_B CostCatValue
	Inner Join FND_VS_VALUES_TL CostCatDesc
	ON CostCatValue.VALUE_ID = CostCatDesc.VALUE_ID
	and CostCatDesc.LANGUAGE = fnd_Global.Current_Language
ON  orDistex.ATTRIBUTE1 = CostCatValue.Value
and CostCatValue.ATTRIBUTE_CATEGORY = 'ACM_Business_Function_VS'

-- Main Project Left Join
Left Join FND_VS_VALUES_B MainPValue
	Inner Join FND_VS_VALUES_TL MainPDesc
	ON MainPValue.VALUE_ID = MainPDesc.VALUE_ID
	and MainPDesc.LANGUAGE = fnd_Global.Current_Language
ON  orDistex.ATTRIBUTE11 = MainPValue.Value
and MainPValue.ATTRIBUTE_CATEGORY = 'ACM_Project_VS_2'

-- Sub Project Left Join
Left Join FND_VS_VALUES_B SubPValue
	Inner Join FND_VS_VALUES_TL SubPDesc
	ON SubPValue.VALUE_ID = SubPDesc.VALUE_ID
	and SubPDesc.LANGUAGE = fnd_Global.Current_Language
ON orDistex.ATTRIBUTE12 = SubPValue.Value
AND orDistex.ATTRIBUTE11 = SubPValue.INDEPENDENT_VALUE
and SubPValue.ATTRIBUTE_CATEGORY = 'ACM_SubProject_VS'
			
-- Process Type Left Join
Left Join FND_VS_VALUES_B ProcessValue
	Inner Join FND_VS_VALUES_TL ProcessDesc
	ON ProcessValue.VALUE_ID = ProcessDesc.VALUE_ID
	and ProcessDesc.LANGUAGE = fnd_Global.Current_Language
ON orDistex.ATTRIBUTE13 = ProcessValue.Value
and ProcessValue.ATTRIBUTE_CATEGORY = 'ACM_ProcessType_VS'			
			
-- Member Type Left Join
Left Join FND_VS_VALUES_B MemberTypeValue
	Inner Join FND_VS_VALUES_TL MemberTypeDesc
	ON MemberTypeValue.VALUE_ID = MemberTypeDesc.VALUE_ID
	and MemberTypeDesc.LANGUAGE = fnd_Global.Current_Language
ON orDistex.ATTRIBUTE6 = MemberTypeValue.Value
and MemberTypeValue.ATTRIBUTE_CATEGORY = 'ACM_Member_Type_VS'				
			
-- Member Left Join
Left Join FND_VS_VALUES_B MemberValue
	Inner Join FND_VS_VALUES_TL MemberDesc
	ON MemberValue.VALUE_ID = MemberDesc.VALUE_ID
	and MemberDesc.LANGUAGE = fnd_Global.Current_Language
ON orDistex.ATTRIBUTE7 = MemberValue.Value
AND orDistex.ATTRIBUTE6 = MemberValue.INDEPENDENT_VALUE
and MemberValue.ATTRIBUTE_CATEGORY = 'ACM_Member_VS'			
	
-- Place Left Join
Left Join FND_VS_VALUES_B PlaceValue
	Inner Join FND_VS_VALUES_TL PlaceDesc
	ON PlaceValue.VALUE_ID = PlaceDesc.VALUE_ID
	and PlaceDesc.LANGUAGE = fnd_Global.Current_Language
ON orDistex.ATTRIBUTE8 = PlaceValue.Value
and PlaceValue.ATTRIBUTE_CATEGORY = 'ACM_Place_VS'
			



Where
-- Mart ayında oluşturulmuş siparişler
-- orheadex.Creation_Date between TO_DATE('01.03.2020', 'dd.MM.yyyy') and  TO_DATE('31.03.2020', 'dd.MM.yyyy')
orheadex.Creation_Date between (:PeriodStartDate) and  (:PeriodEndDate)
-- Invoice ile Eşleşmeyen siparişleri getirmek için koşul
-- and orheadex.PO_HEADER_ID not in 
-- (
 -- SELECT 
 -- DISTINCT
 -- inlinex.PO_HEADER_ID
 -- FROM AP_INVOICE_LINES_ALL inlinex
 -- Inner join AP_INVOICES_ALL inheadX
 -- ON orheadex.PO_HEADER_ID = inlinex.PO_HEADER_ID
-- )
and 

(orheadex.DOCUMENT_STATUS = 'CLOSED FOR RECEIVING' OR orheadex.DOCUMENT_STATUS = 'OPEN')
-- and (horg.Name like 'DO01%'or horg.Name like 'DO02%')
and horg.Name IN (:CompanyBU)
Order By
orheadex.Approved_Date Desc,
orheadex.PO_HEADER_ID

) FromOrder

-- @GoktepeEren -- DarkNightX