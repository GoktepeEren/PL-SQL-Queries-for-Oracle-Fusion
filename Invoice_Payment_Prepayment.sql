Select

api.Legal_Entity_Id,
api.Invoice_Id,
api.Vendor_Id,
api.PO_Header_Id,

xlen.Name,
api.Invoice_Num,
po.SEGMENT1,
supp.VENDOR_NAME,
Translate(api.Description, chr(10)||chr(11)||chr(13), '   ') as Description,
api.Approval_Status,
api.Invoice_Type_Lookup_Code,

api.Invoice_Amount,
api.Total_Tax_Amount,
api.Exchange_Rate,
api.INVOICE_CURRENCY_CODE,
api.PAYMENT_CURRENCY_CODE,  
  
Case api.Payment_Status_Flag 
When 'N' Then 'Not Paid'
When 'Y' Then 'Paid'
Else 'Partial'
End as PaymentStatusFlag,
api.AMOUNT_PAID,

api.Creation_Date as InvoiceCreation,
api.Invoice_Date as InvoiceDate,
api.GL_Date as InvoiceAccountantDate,

pay.payment_id,
pay.payment_profile_id,
pay.payment_document_id,
pay.check_number,
pay.check_date,
pay.payment_method_code,
pay.status_lookup_code,
pay.amount,
pay.currency_code PaymentCurrency,
pay.bank_account_name,
payin.invoice_id AS PInvoice_Id,
payin.period_name,
prof.system_profile_code,
pdoc.payment_document_name,

api_prepay.Invoice_Num as Prepayment_Invoice_num,
pay_prepay.payment_id as prepayment_id,
pay_prepay.payment_profile_id as prepayment_profile_id,
pay_prepay.payment_document_id as prepayment_document_id,
pay_prepay.check_number as prepayment_check,
pay_prepay.check_date as prepayment_check_date,
pay_prepay.payment_method_code as prepayment_method,
pay_prepay.status_lookup_code as prepayment_status ,
pay_prepay.amount as prepayment_amount,
pay_prepay.currency_code as prepayment_Currency,
pay_prepay.bank_account_name as prepayment_bank ,
payin_prepay.invoice_id AS Prepayment_Invoice_Id,
payin_prepay.period_name as prepayment_period, 
prof_prepay.system_profile_code as prepayment_profile,
pdoc_prepay.payment_document_name as prepayment_document


From AP_INVOICES_ALL api
Left Join AP_Invoice_Payments_All payin -- That table has Invoice and Payment Information
    -- We use left join bc we dont need to see all payments and 
    -- we musnt inner bc that code filter just paid invoices with inner join but i want to see all invoices 
    Inner JOIN ap_checks_all pay
        LEFT JOIN iby_acct_pmt_profiles_b prof ON pay.payment_profile_id = prof.payment_profile_id
        LEFT JOIN ce_payment_documents pdoc ON pay.payment_document_id = pdoc.payment_document_id
    ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
ON api.Invoice_Id = payin.Invoice_Id and api.Approval_Status <> 'CANCELLED'

Inner Join POZ_SUPPLIERS_V supp ON api.Vendor_Id = supp.Vendor_Id
Inner Join XLE_ENTITY_PROFILES xlen ON api.LEGAL_ENTITY_ID = xlen.LEGAL_ENTITY_ID
Left Join PO_HEADERS_ALL po ON api.PO_HEADER_ID = po.PO_HEADER_ID
-- We need to show all payments for all prepayment invoices  
Left Join AP_Invoice_Lines_All apil 
    Inner Join AP_INVOICES_ALL api_prepay
        Inner Join AP_Invoice_Payments_All payin_prepay
            Inner JOIN ap_checks_all pay_prepay
                Left JOIN iby_acct_pmt_profiles_b prof_prepay ON pay_prepay.payment_profile_id = prof_prepay.payment_profile_id
                Left JOIN ce_payment_documents pdoc_prepay ON pay_prepay.payment_document_id = pdoc_prepay.payment_document_id
            ON pay_prepay.check_id = payin_prepay.check_id and pay_prepay.STATUS_LOOKUP_CODE <> 'VOIDED'
        ON api_prepay.Invoice_Id = payin_prepay.Invoice_Id 
    ON api_prepay.Invoice_Id = apil.PREPAY_INVOICE_ID and api_prepay.Approval_Status <> 'CANCELLED'
ON api.Invoice_Id = apil.Invoice_Id and apil.LINE_TYPE_LOOKUP_CODE = 'PREPAY'


Where 
-- api.Invoice_Date BETWEEN TO_DATE('01.05.2020','dd.MM.yyyy') AND TO_DATE('01.06.2020','dd.MM.yyyy') 
-- And xlen.Name Like 'Acun Medya Prodü%'
api.Invoice_Date BETWEEN (:FromDate) AND (:ToDate)
And xlen.Name IN (:LegalEntity)
And supp.VENDOR_NAME IN (:VendorName)

Order By api.Invoice_Date DESC