-- New Invoice Line
-- Edited
Select 
FromInvoices.*
From 
(
SELECT

'FromInvoices' as TableType,

horg.Name as BusinessUnit,

inhead.INVOICE_TYPE_LOOKUP_CODE as InvoiceType,

inhead.INVOICE_NUM as InvoiceNumber,

inhead.INVOICE_Date as InvoiceDate,

inhead.Creation_Date as CreationDate,

(Select pay.check_date
From AP_Invoice_Payments_All payin
Inner Join ap_checks_all pay ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
Where payin.Invoice_Id = inhead.Invoice_Id and Rownum <= 1 ) as CheckDate,

inline.Line_Type_Lookup_Code as InvoiceLineType,

sup.Party_Name as SuppName,


-- Category Names Edit
Case 
When cate.Category_Name is not null Then Initcap(cate.Category_Name)
When inhead.Invoice_Type_Lookup_Code = 'PREPAYMENT' Then 'Prepeymant Invoice Category'
When inhead.Invoice_Type_Lookup_Code = 'CREDIT' Then 'Credit Invoice Category'
When inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'ITEM' Then 'Standard Invoice Non-Linked Category'
When inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'TAX' Then 'Standard Invoice Tax Category'
When inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'PREPAY' Then 'Standard Invoice Prepay Category'
When inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'AWT' Then 'Standard Invoice Witholding Category'
Else 'Non-Category'
End as Category_Name,


Case 
When inline.PO_HEADER_ID is not null Then glcodeordist.Segment2 
Else glcode.Segment2 
End as Account,

Case 
When inline.PO_HEADER_ID is not null Then valAccoutNordist.Description 
Else valAccoutN.Description 
End as AccountDescription,


-- Project
Case 
   When inline.Line_Type_Lookup_Code = 'ITEM' and glcode.Segment2 not like '191%' Then   
CASE
    WHEN inhead.ATTRIBUTE_NUMBER5 is not null THEN
        (Select 
			Distinct
			(
			Case 
			When vl.Segment1 = 'DoNotUse-La Romana Common' Then 'La Romana Project Common'
			When vl.Segment1 = 'La Romana Common-Old' Then 'La Romana Project Common'
			Else vl.Segment1
			End)
			From PJF_PROJECTS_ALL_VL vl
			Where inhead.ATTRIBUTE_NUMBER5 = vl.Project_ID)

    WHEN inline.PJC_PROJECT_ID is not null THEN
		(Select 
			Distinct
			(
			Case 
			When vl.Segment1 = 'DoNotUse-La Romana Common' Then 'La Romana Project Common'
			When vl.Segment1 = 'La Romana Common-Old' Then 'La Romana Project Common'
			Else vl.Segment1
			End)
			From PJF_PROJECTS_ALL_VL vl
			Where inline.PJC_PROJECT_ID = vl.Project_ID)
	
	When indist.PJC_PROJECT_ID is not null Then
		(Select 
			Distinct
			(
			Case 
			When vl.Segment1 = 'DoNotUse-La Romana Common' Then 'La Romana Project Common'
			When vl.Segment1 = 'La Romana Common-Old' Then 'La Romana Project Common'
			Else vl.Segment1
			End)
			From PJF_PROJECTS_ALL_VL vl
			Where indist.PJC_PROJECT_ID = vl.Project_ID)
	When inline.ATTRIBUTE12 = 'OPRL.CMMN.0001' or indist.ATTRIBUTE12 = 'OPRL.CMMN.0001'  Then 'La Romana Project Common'
	When inline.ATTRIBUTE12 = 'INVT.LRMN.001' or indist.ATTRIBUTE12 = 'INVT.LRMN.001'  Then 'La Romana Project Common'
	When SubPDesc.Description is not null Then SubPDesc.Description
    When glcodeordist.Segment2 like '157%' Then 'Issue Project'
    Else 'Non-Project'
	END 
    
Else  
        NVL(
                (Select 
                   Distinct
                    (Case 
                    When vl.Segment1 = 'DoNotUse-La Romana Common' Then 'La Romana Project Common'
                    When vl.Segment1 = 'La Romana Common-Old' Then 'La Romana Project Common'
                    Else vl.Segment1
                    End)
                    From AP_INVOICE_LINES_ALL aplin 
                        Inner Join PJF_PROJECTS_ALL_VL vl
                        ON  aplin.PJC_PROJECT_ID = vl.Project_ID
                    Where aplin.Invoice_ID =  inhead.Invoice_ID and vl.Segment1 is not null and rownum <= 1 ), 

                (Select 
                   Distinct
                    (Case 
                    When vl.Segment1 = 'DoNotUse-La Romana Common' Then 'La Romana Project Common'
                    When vl.Segment1 = 'La Romana Common-Old' Then 'La Romana Project Common'
                    Else vl.Segment1
                    End)
                    From AP_INVOICE_DISTRIBUTIONS_ALL aplin 
                        Inner Join PJF_PROJECTS_ALL_VL vl
                        ON  aplin.PJC_PROJECT_ID = vl.Project_ID
                    Where aplin.Invoice_ID =  inhead.Invoice_ID and vl.Segment1 is not null and rownum <= 1 ))

End as Project_Name,
	
	
-- Expenditure_Organization

	CASE
    WHEN inline.PJC_ORGANIZATION_ID is not null THEN
		(Select
			Distinct
			orge.Name
			From HR_ORGANIZATION_UNITS_F_TL orge
			Where orge.Language = 'US' and (Trunc(SysDate) between orge.EFFECTIVE_START_DATE and orge.EFFECTIVE_END_DATE)
			and orge.ORGANIZATION_ID = inline.PJC_ORGANIZATION_ID)
	WHEN indist.PJC_ORGANIZATION_ID is not null THEN
		(Select
			Distinct
			orgE.Name
			From
			HR_ORGANIZATION_UNITS_F_TL orge
			Where orge.Language = 'US' and (Trunc(SysDate) between orge.EFFECTIVE_START_DATE and orge.EFFECTIVE_END_DATE)
			and orge.ORGANIZATION_ID = indist.PJC_ORGANIZATION_ID)
    Else 'Non-ExpOrganization'
	END as Expenditure_Organization,


-- BusinessFunction (CostCategory) --------------------------------------------
  
   CASE
   When inhead.Invoice_Type_Lookup_Code = 'PREPAYMENT' Then 'Prepayment'
   WHEN inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'TAX' Then 'Tax'
   WHEN inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'PREPAY' Then 'Prepayment'
   WHEN inhead.Invoice_Type_Lookup_Code = 'STANDARD' and inline.Line_Type_Lookup_Code = 'AWT' Then 'WitholdingTax'
   When CostCatDesc.DESCRIPTION is not null Then CostCatDesc.DESCRIPTION
   Else 'Non-CostCategory'
   End as BusinessFunction,
 	
-- Main Project--------------------------------------------
	
	Case 
    When MainPDesc.Description is not null Then MainPDesc.Description
    Else 'Non-MainProject' End as Main_Project,
	
-- Sub Project--------------------------------------------
   
   Case 
   When SubPDesc.Description is not null Then SubPDesc.Description
   Else 'Non-SubProject' End
    as Sub_Project,

-- Process Type --------------------------------------------
	
   Case 
   When ProcessDesc.Description is not null Then ProcessDesc.Description
   Else 'Non-Process' End
    as ProcessType,
	
-- Member Type --------------------------------------------

    Case 
   When MemberTypeDesc.DESCRIPTION is not null Then MemberTypeDesc.DESCRIPTION
   Else 'Non-MemberType' End
	 as Member_Type,

-- Member --------------------------------------------

    Case 
   When MemberDesc.DESCRIPTION is not null Then MemberDesc.DESCRIPTION
   Else 'Non-Member' End
	 as Member,

-- Place --------------------------------------------

    Case 
   When PlaceDesc.DESCRIPTION is not null Then PlaceDesc.DESCRIPTION
   Else 'Non-Place' End
	
	 as Place,

indist.REVERSAL_FLAG ,

CASE
When inhead.Invoice_Currency_Code = 'USD' Then indist.Amount
Else Trunc(indist.Amount / TRUNC(drate.Conversion_Rate,2), 2) 
End as DistAmountUSD,

indist.Amount as DistAmountInvoiceCurrency,

(indist.Amount * NVL(inhead.EXCHANGE_RATE,1)) as DistAmountLedgerCurrency,

inhead.Invoice_Currency_Code as InvoiceCurrency,

(Select inheadx.Invoice_Currency_Code From AP_INVOICES_ALL inheadx Where inheadx.Exchange_Rate is null and inhead.Org_Id = inheadx.Org_Id and Rownum <= 1) as LedgerCurrency,

inhead.Exchange_Rate as InvoiceExchangeRate,

TO_CHAR(inhead.INVOICE_DATE, 'YYYY, MONTH') as InvoiceDateMonth,

Case
	When inhead.PAYMENT_STATUS_FLAG = 'P' Then 'Partial Paid' 
	When inhead.PAYMENT_STATUS_FLAG = 'Y' Then 'Paid' 
	When inhead.PAYMENT_STATUS_FLAG = 'N' Then 'Not Paid' 
End

as PaymentStatus,
	
-- Case 
-- When ((indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' OR indist.LINE_TYPE_LOOKUP_CODE = 'ITEM') And inline.Line_Number = 1 and inline.Line_Type_Lookup_Code <> 'MISCELLANEOUS' ) Then NVL(inhead.Amount_Paid,0) 
-- When inline.Line_Type_Lookup_Code = 'MISCELLANEOUS' Then NVL((indist.Amount * -1),0)
-- Else 0
-- End as PaidAmountInvoiceCurrency, 


Case
	When inhead.PAYMENT_STATUS_FLAG = 'Y'
		Then  
			Case
				When inline.Line_Type_Lookup_Code = 'MISCELLANEOUS' or inline.Line_Type_Lookup_Code = 'PREPAY' or inline.Line_Type_Lookup_Code = 'AWT' Then 0
				Else NVL(indist.Amount, 0)
				End 
	When inhead.PAYMENT_STATUS_FLAG = 'P' Then  NVL(inhead.Amount_Paid, 1) / 
		(Select CountLine From
			(Select apdistx.Invoice_Id, Count(Rownum) as CountLine 
			From ap_invoice_distributions_all apdistx 
			Where apdistx.LINE_TYPE_LOOKUP_CODE <> 'NONREC_TAX' 
			and (indist.REVERSAL_FLAG is null Or indist.REVERSAL_FLAG = 'N')
			and apdistx.Invoice_ID = inhead.Invoice_ID Group By apdistx.Invoice_Id)) 
	When inhead.PAYMENT_STATUS_FLAG = 'N' Then 0 
End as PaidAmountInvoiceCurrency,

-- Case 
-- When ((indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' OR indist.LINE_TYPE_LOOKUP_CODE = 'ITEM') And inline.Line_Number = 1 and inline.Line_Type_Lookup_Code <> 'MISCELLANEOUS' ) Then NVL(inhead.Amount_Paid * NVL(inhead.EXCHANGE_RATE,1),0) 
-- When inline.Line_Type_Lookup_Code = 'MISCELLANEOUS' Then NVL((indist.Amount * -1 * NVL(inhead.EXCHANGE_RATE,1)),0)
-- Else 0
-- End as PaidAmountLedgerCurrency, 


Case
	When inhead.PAYMENT_STATUS_FLAG = 'Y' Then 
		Case
			When inline.Line_Type_Lookup_Code = 'MISCELLANEOUS' or inline.Line_Type_Lookup_Code = 'PREPAY' or  inline.Line_Type_Lookup_Code = 'AWT' Then 0
			Else NVL(indist.Amount * NVL(inhead.EXCHANGE_RATE,1), 0)
			End 		  
	When inhead.PAYMENT_STATUS_FLAG = 'P' Then  NVL(inhead.Amount_Paid * NVL(inhead.EXCHANGE_RATE,1), 1) / 
	(Select CountLine From
			(Select apdistx.Invoice_Id, Count(Rownum) as CountLine 
			From ap_invoice_distributions_all apdistx 
			Where apdistx.LINE_TYPE_LOOKUP_CODE <> 'NONREC_TAX' 
			and (indist.REVERSAL_FLAG is null Or indist.REVERSAL_FLAG = 'N')
			and apdistx.Invoice_ID = inhead.Invoice_ID Group By apdistx.Invoice_Id))
	When inhead.PAYMENT_STATUS_FLAG = 'N' Then 0 
End as PaidAmountLedgerCurrency,

-- Case 
-- 	When ((indist.LINE_TYPE_LOOKUP_CODE = 'ACCRUAL' OR indist.LINE_TYPE_LOOKUP_CODE = 'ITEM') And inline.Line_Number = 1 and inline.Line_Type_Lookup_Code <> 'MISCELLANEOUS') Then
-- 		NVL(CASE
-- 		When inhead.Invoice_Currency_Code = 'USD' Then inhead.Amount_Paid
-- 		Else TRUNC(inhead.Amount_Paid / TRUNC(drate.Conversion_Rate,2),2) 
-- 		End, 0)
--     When inline.Line_Type_Lookup_Code = 'MISCELLANEOUS'
--     Then NVL(CASE
--             When inhead.Invoice_Currency_Code = 'USD' Then (indist.Amount * -1)
--             Else Trunc((indist.Amount * -1) / TRUNC(drate.Conversion_Rate,2), 2) 
--             End, 0)

-- Else 0
-- End	
-- 	as PaidAmountUSD


Case
	When inhead.PAYMENT_STATUS_FLAG = 'Y' 
		Then 
			CASE When inhead.Invoice_Currency_Code = 'USD' 
				Then
					Case
					When inline.Line_Type_Lookup_Code = 'MISCELLANEOUS' or inline.Line_Type_Lookup_Code = 'PREPAY' or inline.Line_Type_Lookup_Code = 'AWT' Then 0
					Else indist.Amount
					End  
				Else 
					Case
					When inline.Line_Type_Lookup_Code = 'MISCELLANEOUS' or inline.Line_Type_Lookup_Code = 'PREPAY' or inline.Line_Type_Lookup_Code = 'AWT' Then 0
					Else NVL(TRUNC(indist.Amount / TRUNC(drate.Conversion_Rate,2),2) , 0)
					End
				End
	When inhead.PAYMENT_STATUS_FLAG = 'P' 
		Then  NVL(CASE When inhead.Invoice_Currency_Code = 'USD' Then inhead.Amount_Paid Else TRUNC(inhead.Amount_Paid / TRUNC(drate.Conversion_Rate,2),2) End, 1) / 
		(Select CountLine From
			(Select apdistx.Invoice_Id, Count(Rownum) as CountLine 
			From ap_invoice_distributions_all apdistx 
			Where apdistx.LINE_TYPE_LOOKUP_CODE <> 'NONREC_TAX' 
			and (indist.REVERSAL_FLAG is null Or indist.REVERSAL_FLAG = 'N')
			and apdistx.Invoice_ID = inhead.Invoice_ID Group By apdistx.Invoice_Id))
	When inhead.PAYMENT_STATUS_FLAG = 'N' Then 0 
End as PaidAmountUSD

From 
AP_INVOICE_LINES_ALL inline
INNER JOIN AP_INVOICES_ALL inhead 
	Inner Join HZ_PARTIES sup 
	On sup.PARTY_ID = inhead.PARTY_ID
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
-- Prepayment olmayan satırları ve Eşleşip Prepayment olan belirtilen tarihler arasında olan 
-- and (inline.Line_Type_Lookup_Code != 'PREPAY' OR (inline.Line_Type_Lookup_Code = 'PREPAY' and (Select prepay.Invoice_Date From AP_INVOICES_ALL prepay Where prepay.Invoice_Id = inline.PREPAY_INVOICE_ID) Between (:PeriodStartDate) and  (:PeriodEndDate) ) ) 
and inhead.VENDOR_ID != '300000009593655' -- Intercompany 'Acun Media Production DR SRL' 

and horg.Name IN (:CompanyBU)


and (indist.REVERSAL_FLAG is null Or indist.REVERSAL_FLAG = 'N')

Order By
inhead.INVOICE_DATE DESC,
inline.Invoice_Id,
inline.Line_Number
) FromInvoices

-- UNION ALL

-- Select
-- FromExtTransaciton.*
-- From 
-- (
-- Select
-- 'FromExtTransaciton' as TableType,
-- exttra.BUSINESS_UNIT_ID as BusinessUnit,
-- horgext.Name as CompanyName,

-- exttra.EXTERNAL_TRANSACTION_ID as ExTransactionId,
-- To_Char(exttra.TRANSACTION_ID) as TransactionNumber,


-- Case exttra.TRANSACTION_TYPE
-- When 'ACH'		Then 'Automated clearing house'
-- When 'BKA' 		Then 'Bank adjustment'
-- When 'BKF' 		Then 'Fee'
-- When 'BNB'		Then 'Banka Belgesi'
-- When 'CHK'		Then 'Check'
-- When 'EFT'		Then 'Electronic funds transfer'
-- When 'INT'		Then 'Interest'
-- When 'KRK'		Then 'Credit Card'
-- When 'KTD'		Then 'Kasa Tediye'
-- When 'KTH'		Then 'Kasa Tahsil'
-- When 'LBX'		Then 'Lockbox'
-- When 'MSC'		Then 'Miscellaneous'
-- When 'ORA_REV'	Then 'Reversal'
-- When 'ZBA' 		Then 'Zero balancing'
-- Else '-'
-- End as TRANSACTIONType,

-- Translate(exttra.DESCRIPTION, chr(10)||chr(11)||chr(13), '   ')  as TransactionDesc,

-- Null as Supp,
-- Null as SuppSite,
-- 'External Transactions' as SuppName,
-- Null as SuppSiteName,

-- Null as TermsId,
-- Null as TermName,

-- Null as TraType,
-- Null as LineNum,
-- exttra.SOURCE,

-- Null as orderid,
-- Null as orderlineid,

-- Null as ordernumber,

-- Case
-- When exttra.STATUS = 'UNR' Then 'Unreconciled'
-- When exttra.STATUS = 'UNR' Then 'Reconciled' 
-- ELSE ''
-- End as TransactionStatus,

-- Null as OrLineNumber,
-- Null as LineStatus,

-- Null as LineType,
-- Null as InvItemId,
-- Null as InvItemName,

-- Null as OrderLineDesc,
-- Null as InvoiceLineDescription,

-- Null as OrderLineDeliverToLoc,
-- Null as CatId,

-- Null as OrderLineCategory,
-- Null as Category_Name,
-- Null as OrderLineDiscount,
-- Null as OrderLineMeaCode			,
-- Null as OrderLineQuantity           ,
-- Null as OrderLiQuantityOrdered      ,

-- Null as OrderLiQuantityDelivered    ,
-- Null as OrderLiQuantityBilled       ,
-- Null as OrderLiQuantityCanceled     ,
-- Null as OrderLineListPrice          ,
-- Null as OrderLineUnitPrice          ,
-- Null as OrderLineAmountWTax         ,
-- Null as OrderLineAmountWTaxUSD      ,
-- Null as Buyer                       ,
-- Null as PrepayInvoicedId            ,
-- Null as LinkedPrepayment            ,
-- Null as PrepayLineNumber            ,
-- Null as TaxRateCode                 ,
-- Null as Tax_Rate                    ,


-- exttra.OFFSET_CCID as AccountId,
-- glcodeext.Segment2 as Account,
-- valAccoutNext.Description as AccountDescription,

-- (valAccoutNext.Description || ' - ' || glcodeext.Segment2) as AccountWideDesc,



-- Null as LineProjectId,
-- Null as LineOrganizationId,
-- Null as DistProjId,
-- Null as DistPrjOrgId,
-- Null as Project_Name,
-- Null as Expenditure_Organization,

-- Null as BusinessFunction,
-- Null as Main_Project,
-- Null as Sub_Project,
-- Null as ProcessType,
-- Null as Member_Type,
-- Null as Member,
-- Null as Place,

-- Null as InDistLineType,

-- exttra.AMOUNT as Amount,

-- CASE
-- When exttra.CURRENCY_CODE = 'USD' Then exttra.AMOUNT 
-- Else TRUNC(exttra.AMOUNT  / TRUNC(drateext.Conversion_Rate,2),2) 
-- End as AmountUsd,

-- Null as InvoiceExchangeRate,

-- Case 
-- WHEN exttra.CURRENCY_CODE = 'USD' Then 1
-- Else TRUNC(drateext.Conversion_Rate,2)
-- End as DailyRateUSD,

-- exttra.CURRENCY_CODE as TransCurrency,

-- Null as PaymentCurrency,
-- 'Paid' as PaymentStatus,

-- exttra.AMOUNT as PaidAmount,

-- CASE
-- When exttra.CURRENCY_CODE = 'USD' Then exttra.AMOUNT 
-- Else TRUNC(exttra.AMOUNT  / TRUNC(drateext.Conversion_Rate,2),2) 
-- End as PaidAmountUsd,


-- exttra.Bank_Account_Id as BankAccountId,

-- Null as OrderLineStartPeriodDate,
-- Null as OrderLineEndPeriodDate,
-- Null as OrderCreationDate,
-- Null as OrderSubmitDate,
-- Null as OrderApprovedDate,
-- Null as Terms_Date,
-- Null as Period_Name,
-- Null as Accounting_Date,
-- Null as InvoiceExchangeDate,
-- exttra.CREATION_DATE as TraCreationDate,
-- TO_CHAR(exttra.TRANSACTION_DATE, 'YYYY, MONTH') as TransactionDateMonth,
-- exttra.TRANSACTION_DATE as TransactionDate,
-- Null as InvoiceCreationBy,
-- Null as LinkedPrepaymentDate,

-- Null as LineCanceled,
-- Null as InvoiceCanceledDate,
-- Null as InvoiceCanceledAmount

-- From 
-- CE_EXTERNAL_TRANSACTIONS exttra
-- 	Inner Join GL_CODE_COMBINATIONS glcodeext
-- 		Inner Join FND_VS_VALUES_B valAccoutext
-- 			Inner Join FND_VS_VALUES_TL valAccoutNext 
-- 			ON valAccoutext.Value_Id = valAccoutNext.Value_Id 
-- 			and valAccoutNext.LANGUAGE= FND_GLOBAL.Current_Language
			
-- 		ON valAccoutext.Value = glcodeext.Segment2 and valAccoutext.ATTRIBUTE_CATEGORY = 'ACM_Account'
-- 	ON exttra.OFFSET_CCID  = glcodeext.CODE_COMBINATION_ID
-- 	Inner Join hr_organization_units horgext
--     ON horgext.Organization_Id = exttra.BUSINESS_UNIT_ID
-- 	Left Join gl_daily_rates drateext            
-- 	ON drateext.From_Currency = 'USD' and drateext.TO_Currency = exttra.CURRENCY_CODE
-- 	And drateext.Conversion_Type = 'Corporate'
-- 	and drateext.CONVERSION_DATE = exttra.TRANSACTION_DATE	
-- Where 
-- exttra.STATUS <> 'VOID'
-- and horgext.Name IN (:CompanyBU)
-- and (exttra.TRANSACTION_DATE between ((:PeriodStartDate)) and  (:PeriodEndDate))
-- Order By exttra.TRANSACTION_DATE Desc
-- ) FromExtTransaciton

-- UNION ALL 

-- Select FromOrder.*
-- From 
-- (
-- -- New Invoice Line

-- SELECT

-- 'FromOrders' as TableType,
-- horg.Name as BusinessUnit,

-- Null as Null3,

-- null as InvoiceDate,

-- null as CreationDate,

-- null as CheckDate,

-- Null as Null6,

-- sup.VENDOR_NAME as SuppName,


-- Initcap(cate.Category_Name),


-- glcode.Segment2 as Account,
-- valAccoutN.Description as AccountDescription,




-- -- Project

-- CASE
--     WHEN orDistex.PJC_PROJECT_ID is not null THEN
-- 		(Select 
-- 		Distinct
-- 		(
-- 			Case 
-- 			When vl.Segment1 = 'DoNotUse-La Romana Common' Then 'La Romana Project Common'
-- 			When vl.Segment1 = 'La Romana Common-Old' Then 'La Romana Project Common'
-- 			Else vl.Segment1
-- 			End
-- 		)
-- 		From PJF_PROJECTS_ALL_VL vl
-- 		Where orDistex.PJC_PROJECT_ID = vl.Project_ID)
-- 	When orDistex.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Project Common'
-- 	When orDistex.ATTRIBUTE12 = 'INVT.LRMN.001'  Then 'La Romana Project Common'	
-- 	When SubPDesc.Description is not null Then SubPDesc.Description
--     Else 'Non-Project'
-- End
-- as Project_Name,
			
	
-- -- Expenditure_Organization

-- (Select
-- Distinct
-- NVL(orge.Name, 'Non-ExpOrganization')
-- From HR_ORGANIZATION_UNITS_F_TL orge
-- Where orge.Language = fnd_Global.Current_Language and (Trunc(SysDate) between orge.EFFECTIVE_START_DATE and orge.EFFECTIVE_END_DATE)
-- and orge.ORGANIZATION_ID = orDistex.PJC_ORGANIZATION_ID)
-- as Expenditure_Organization,		
	
-- -- BusinessFunction (CostCategory) --------------------------------------------
  
--   Case 
--     When CostCatDesc.DESCRIPTION is not null Then CostCatDesc.DESCRIPTION
--     Else 'Non-MainProject' End
--     as BusinessFunction,
 	
-- -- Main Project--------------------------------------------
	
-- 	Case 
--     When MainPDesc.Description is not null Then MainPDesc.Description
--     Else 'Non-MainProject' End as Main_Project,
	
-- -- Sub Project--------------------------------------------
   
--    Case 
--    When SubPDesc.Description is not null Then SubPDesc.Description
--    Else 'Non-SubProject' End
--     as Sub_Project,

-- -- Process Type --------------------------------------------
	
--    Case 
--    When ProcessDesc.Description is not null Then ProcessDesc.Description
--    Else 'Non-Process' End
--     as ProcessType,
	
-- -- Member Type --------------------------------------------

--     Case 
--    When MemberTypeDesc.DESCRIPTION is not null Then MemberTypeDesc.DESCRIPTION
--    Else 'Non-MemberType' End
-- 	 as Member_Type,

-- -- Member --------------------------------------------

--     Case 
--    When MemberDesc.DESCRIPTION is not null Then MemberDesc.DESCRIPTION
--    Else 'Non-Member' End
-- 	 as Member,

-- -- Place --------------------------------------------

--     Case 
--    When PlaceDesc.DESCRIPTION is not null Then PlaceDesc.DESCRIPTION
--    Else 'Non-Place'
-- 	End
-- 	 as Place,


-- Case 
-- WHEN orheadex.CURRENCY_CODE = 'USD' Then Trunc((orDistex.RECOVERABLE_INCLUSIVE_TAX + orDistex.RECOVERABLE_TAX + orDistex.TAX_EXCLUSIVE_AMOUNT),2)
-- Else Trunc(Trunc((orDistex.RECOVERABLE_INCLUSIVE_TAX + orDistex.RECOVERABLE_TAX + orDistex.TAX_EXCLUSIVE_AMOUNT),2) / TRUNC(dorderrate.Conversion_Rate,2), 2)
-- End OrderDistAmountUSD, -- InvoiceDistAmountUSD


-- Null as DistAmountInvoiceCurrency,

-- orheadex.CURRENCY_CODE as OrderCurrency,

-- TO_CHAR(orheadex.Creation_date, 'YYYY, MONTH')  as OrderDateMonth,

-- Null as PaymentStatus,
-- Null as PaidAmountInvoiceCurrency,
-- Null as PaidAmountUSD

-- From 
-- PO_LINES_ALL orLineex
-- INNER JOIN PO_HEADERS_ALL orheadex 
-- 	Inner Join POZ_SUPPLIERS_V sup 
-- 	On sup.VENDOR_ID = orheadex.VENDOR_ID
-- 	Inner Join hr_organization_units horg
--     ON horg.Organization_Id = orheadex.BILLTO_BU_ID
-- 	Left Join gl_daily_rates dorderrate            
-- 	ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = orheadex.CURRENCY_CODE
-- 	And dorderrate.Conversion_Type = 'Corporate' 
-- 	and dorderrate.CONVERSION_DATE = To_Date(To_Char(orheadex.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
-- On orLineex.PO_HEADER_Id = orheadex.PO_HEADER_Id
-- Inner Join PO_DISTRIBUTIONS_ALL orDistex 
-- 			Inner Join GL_CODE_COMBINATIONS glcode 
-- 				Inner Join FND_VS_VALUES_B valAccout
-- 					Inner Join FND_VS_VALUES_TL valAccoutN 
-- 					ON valAccout.Value_Id = valAccoutN.Value_Id 
-- 					and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language
-- 				ON valAccout.Value = glcode.Segment2 and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
-- 			ON orDistex.CODE_COMBINATION_ID  = glcode.CODE_COMBINATION_ID
-- ON orDistex.PO_LINE_ID = orLineex.PO_LINE_ID
-- Left join EGP_Categories_TL cate ON cate.Category_Id = orLineex.Category_Id and cate.LANGUAGE= FND_GLOBAL.Current_Language


-- -- (BusinessFunction) Cost Category Left Join
-- Left Join FND_VS_VALUES_B CostCatValue
-- 	Inner Join FND_VS_VALUES_TL CostCatDesc
-- 	ON CostCatValue.VALUE_ID = CostCatDesc.VALUE_ID
-- 	and CostCatDesc.LANGUAGE = fnd_Global.Current_Language
-- ON  orDistex.ATTRIBUTE1 = CostCatValue.Value
-- and CostCatValue.ATTRIBUTE_CATEGORY = 'ACM_Business_Function_VS'

-- -- Main Project Left Join
-- Left Join FND_VS_VALUES_B MainPValue
-- 	Inner Join FND_VS_VALUES_TL MainPDesc
-- 	ON MainPValue.VALUE_ID = MainPDesc.VALUE_ID
-- 	and MainPDesc.LANGUAGE = fnd_Global.Current_Language
-- ON  orDistex.ATTRIBUTE11 = MainPValue.Value
-- and MainPValue.ATTRIBUTE_CATEGORY = 'ACM_Project_VS_2'

-- -- Sub Project Left Join
-- Left Join FND_VS_VALUES_B SubPValue
-- 	Inner Join FND_VS_VALUES_TL SubPDesc
-- 	ON SubPValue.VALUE_ID = SubPDesc.VALUE_ID
-- 	and SubPDesc.LANGUAGE = fnd_Global.Current_Language
-- ON orDistex.ATTRIBUTE12 = SubPValue.Value
-- AND orDistex.ATTRIBUTE11 = SubPValue.INDEPENDENT_VALUE
-- and SubPValue.ATTRIBUTE_CATEGORY = 'ACM_SubProject_VS'
			
-- -- Process Type Left Join
-- Left Join FND_VS_VALUES_B ProcessValue
-- 	Inner Join FND_VS_VALUES_TL ProcessDesc
-- 	ON ProcessValue.VALUE_ID = ProcessDesc.VALUE_ID
-- 	and ProcessDesc.LANGUAGE = fnd_Global.Current_Language
-- ON orDistex.ATTRIBUTE13 = ProcessValue.Value
-- and ProcessValue.ATTRIBUTE_CATEGORY = 'ACM_ProcessType_VS'			
			
-- -- Member Type Left Join
-- Left Join FND_VS_VALUES_B MemberTypeValue
-- 	Inner Join FND_VS_VALUES_TL MemberTypeDesc
-- 	ON MemberTypeValue.VALUE_ID = MemberTypeDesc.VALUE_ID
-- 	and MemberTypeDesc.LANGUAGE = fnd_Global.Current_Language
-- ON orDistex.ATTRIBUTE6 = MemberTypeValue.Value
-- and MemberTypeValue.ATTRIBUTE_CATEGORY = 'ACM_Member_Type_VS'				
			
-- -- Member Left Join
-- Left Join FND_VS_VALUES_B MemberValue
-- 	Inner Join FND_VS_VALUES_TL MemberDesc
-- 	ON MemberValue.VALUE_ID = MemberDesc.VALUE_ID
-- 	and MemberDesc.LANGUAGE = fnd_Global.Current_Language
-- ON orDistex.ATTRIBUTE7 = MemberValue.Value
-- AND orDistex.ATTRIBUTE6 = MemberValue.INDEPENDENT_VALUE
-- and MemberValue.ATTRIBUTE_CATEGORY = 'ACM_Member_VS'			
	
-- -- Place Left Join
-- Left Join FND_VS_VALUES_B PlaceValue
-- 	Inner Join FND_VS_VALUES_TL PlaceDesc
-- 	ON PlaceValue.VALUE_ID = PlaceDesc.VALUE_ID
-- 	and PlaceDesc.LANGUAGE = fnd_Global.Current_Language
-- ON orDistex.ATTRIBUTE8 = PlaceValue.Value
-- and PlaceValue.ATTRIBUTE_CATEGORY = 'ACM_Place_VS'
			



-- Where
-- -- Mart ayında oluşturulmuş siparişler
-- -- orheadex.Creation_Date between TO_DATE('01.03.2020', 'dd.MM.yyyy') and  TO_DATE('31.03.2020', 'dd.MM.yyyy')
-- orheadex.Creation_Date between (:PeriodStartDate) and  (:PeriodEndDate)
-- -- Invoice ile Eşleşmeyen siparişleri getirmek için koşul
-- -- and orheadex.PO_HEADER_ID not in 
-- -- (
--  -- SELECT 
--  -- DISTINCT
--  -- inlinex.PO_HEADER_ID
--  -- FROM AP_INVOICE_LINES_ALL inlinex
--  -- Inner join AP_INVOICES_ALL inheadX
--  -- ON orheadex.PO_HEADER_ID = inlinex.PO_HEADER_ID
-- -- )
-- and 

-- (orheadex.DOCUMENT_STATUS = 'CLOSED FOR RECEIVING' OR orheadex.DOCUMENT_STATUS = 'OPEN')
-- -- and (horg.Name like 'DO01%'or horg.Name like 'DO02%')
-- and horg.Name IN (:CompanyBU)
-- Order By
-- orheadex.Approved_Date Desc,
-- orheadex.PO_HEADER_ID

-- ) FromOrder

-- @GoktepeEren -- DarkNightX