Select 

glb.JE_BATCH_ID "Batch Id",
gll.JE_HEADER_ID "Header_Id",
gll.LEDGER_ID "Ledger_Id",
gll.CODE_COMBINATION_ID "Code_Id",
gled.Name "Ledger_Name",
gll.PERIOD_NAME "Period",
glb.NAME "Batch Name",
glb.DESCRIPTION "Batch Description",
glb.STATUS "Batch Status",
glh.Posted_Date "Posted Date",
glh.NAME "Journal Name",
glh.DESCRIPTION "Journal Description",
import.Reference_6,
ap_dist.accounting_event_id invsupp, 
ap_pay.accounting_event_id paysupp,
Case 
When glh.JE_CATEGORY = 'Payments' Then ap_pay.VENDOR_NAME
When glh.JE_CATEGORY = 'Purchase Invoices' Then ap_dist.VENDOR_NAME 
Else '' 
End as SuppName,
Case 
When glh.JE_CATEGORY = 'Payments' Then ap_pay.PARTY_SITE_NAME
When glh.JE_CATEGORY = 'Purchase Invoices' Then ap_dist.PARTY_SITE_NAME
Else '' 
End as SuppSiteName,
glh.JE_SOURCE "Source",
glh.JE_CATEGORY "Category",
gll.JE_LINE_NUM"Line_Number",
gll.DESCRIPTION "Line_Description",
gcc.Segment2 "Account",
valAccoutNordist.Description as AccountDesc,
gll.ENTERED_DR "Entered Debit",
gll.ENTERED_CR "Entered Credit",

Sum(NVL(gll.ENTERED_DR,0) - NVL(gll.ENTERED_CR, 0))OVER(ORDER BY gll.JE_HEADER_ID, gll.JE_LINE_NUM) as Entered_Fark ,

gll.ACCOUNTED_DR "Accounted Debit",
gll.ACCOUNTED_CR "Accounted Crebit",

Sum(NVL(gll.ACCOUNTED_DR,0) - NVL(gll.ACCOUNTED_CR,0))OVER(ORDER BY gll.JE_HEADER_ID, gll.JE_LINE_NUM) as Accounting_Fark, 

glh.CURRENCY_CODE "Currency"

From  GL_JE_BATCHES glb
Inner Join GL_JE_HEADERS glh 
    Inner Join GL_JE_LINES gll
        Inner Join GL_LEDGERS gled
        ON gll.Ledger_Id = gled.Ledger_Id 
        Inner Join  GL_CODE_COMBINATIONS gcc
            Inner Join FND_VS_VALUES_B valAccoutordist
					Inner Join FND_VS_VALUES_TL valAccoutNordist
					ON valAccoutordist.Value_Id = valAccoutNordist.Value_Id 
					and valAccoutNordist.LANGUAGE = FND_GLOBAL.Current_Language
			ON valAccoutordist.Value = gcc.Segment2 and valAccoutordist.ATTRIBUTE_CATEGORY = 'ACM_Account'
        ON gll.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID
        Left Join GL_Import_References import
            Left Join  
                (
                    Select Distinct dist2.Accounting_Event_Id, inhead.Invoice_Id, sup.VENDOR_NAME, supsite.PARTY_SITE_NAME
                    From ap_invoice_distributions_all dist2
                    Inner Join ap_invoices_All inhead
                        Inner Join POZ_SUPPLIERS_V sup 
                        On sup.VENDOR_ID = inhead.VENDOR_ID
                        Inner Join POZ_SUPPLIER_SITES_V supsite
                        On supsite.VENDOR_SITE_ID = inhead.VENDOR_SITE_ID
                    ON inhead.Invoice_Id = dist2.Invoice_Id  
                ) ap_dist
            ON import.Reference_6 = ap_dist.accounting_event_id
            Left Join 
                (
                    Select Distinct pay2.Accounting_Event_Id, ap_check.Check_Id, supx.VENDOR_NAME, supsitex.PARTY_SITE_NAME
                    From ap_payment_history_all pay2
                    Inner Join ap_checks_all ap_check
                        Inner Join POZ_SUPPLIERS_V supx 
                        On supx.VENDOR_ID = ap_check.VENDOR_ID
                        Inner Join POZ_SUPPLIER_SITES_V supsitex
                        On supsitex.VENDOR_SITE_ID = ap_check.VENDOR_SITE_ID
                    ON pay2.Check_Id = ap_check.Check_Id
                ) ap_pay
            ON import.Reference_6 = ap_pay.accounting_event_id
        ON gll.JE_HEADER_ID  = import.JE_HEADER_ID and gll.JE_LINE_NUM = import.JE_LINE_NUM
    On glh.JE_HEADER_ID = gll.JE_HEADER_ID
ON glb.JE_BATCH_ID = glh.JE_BATCH_ID

Where  
gled.Name IN (:LEDGER)
-- gled.Name IN 'DO01_Ledger'
AND gll.PERIOD_NAME IN (:PERIOD)
-- AND gll.PERIOD_NAME = '2019-01'
-- AND glb.STATUS IN (:STATUS)
AND gcc.Segment2 IN (:ACCOUNT)
-- AND glh.JE_SOURCE IN (:SOURCE)
-- AND glh.JE_CATEGORY IN (:CATEGORY)
Order BY gll.JE_HEADER_ID, gll.JE_LINE_NUM