Select
 Distinct 
  xlel.NAME "Entity Name",
  xlel.LEGAL_ENTITY_IDENTIFIER "Entity Iden",
  aia.invoice_id AS Pre_Invoice_Id,
  aia.vendor_id "Vendor_Id",
  aia.invoice_num "Pre_Invoice_Number",
  supp.vendor_name "Vendor_Name",
  aia.INVOICE_TYPE_LOOKUP_CODE "Pre_Invoice Type",
  aia.invoice_date "Pre_Invoice_Date",
  aia.creation_date "Pre_Creation_Date",
  aia.invoice_currency_code "Pre_Invoice_Currency",
  aia.invoice_amount "Pre_Invoice_Amount",
  tbl_prepay.PO_HEADER_ID "PO_Id",
  tbl_prepay.Segment1 "Order_Name",
  tbl_pay.PAYMENT_ID "Payment_Id",
  tbl_pay.PAYMENT_PROFILE_ID,
  tbl_pay.Payment_Document_Id,
  tbl_pay.CHECK_NUMBER "Payment_Ref_Number",
  tbl_pay.PAYMENT_METHOD_CODE "Payment_Method",
  tbl_pay.STATUS_LOOKUP_CODE "Payment_Status",
  tbl_pay.AMOUNT "Payment_Amount",
  tbl_pay.CURRENCY_CODE "Payment_Currency",
  tbl_pay.BANK_ACCOUNT_NAME "Bank_Account",
  tbl_pay.PInvoice_Id,
  tbl_pay.PERIOD_NAME "Payment_Period",
  tbl_pay.SYSTEM_PROFILE_CODE "Payment_Profile",
  tbl_pay.PAYMENT_DOCUMENT_NAME "Payment_Document",
tbl_prepay.LInvoice_Id "Linked_Invoice_Id",
tbl_prepay.INVOICE_NUM "Linked_Invoice_Number",
tbl_prepay.Linked_Invoice_Amount,
tbl_prepay.Linked_Inv_Paid_Amount, 
tbl_prepay.Linked_Invoice_Diff,
tbl_prepay.Linked_Invoice_Currency
From
  AP_INVOICES_ALL aia
  Inner Join POZ_SUPPLIERS_V supp ON aia.VENDOR_ID = supp.VENDOR_ID
  Left Join PO_HEADERS_ALL pha ON pha.PO_HEADER_ID = aia.PO_HEADER_ID
  Inner Join XLE_ENTITY_PROFILES xlel ON aia.legal_entity_id = xlel.legal_entity_id
  Left Join (
    Select
      Distinct pay.PAYMENT_ID,
      pay.PAYMENT_PROFILE_ID,
      pay.Payment_Document_Id,
      pay.CHECK_NUMBER,
      pay.PAYMENT_METHOD_CODE,
      pay.STATUS_LOOKUP_CODE,
      pay.AMOUNT,
      pay.CURRENCY_CODE,
      pay.BANK_ACCOUNT_NAME,
      payin.INVOICE_ID as PInvoice_Id,
      payin.PERIOD_NAME,
      prof.SYSTEM_PROFILE_CODE,
      pdoc.PAYMENT_DOCUMENT_NAME
    From
      AP_Checks_All pay
      Inner Join AP_INVOICE_PAYMENTS_ALL payin ON pay.CHECK_ID = payin.CHECK_ID
      Inner Join IBY_ACCT_PMT_PROFILES_B prof ON pay.PAYMENT_PROFILE_ID = prof.PAYMENT_PROFILE_ID
      Left Join CE_PAYMENT_DOCUMENTS pdoc ON pay.PAYMENT_DOCUMENT_ID = pdoc.PAYMENT_DOCUMENT_ID
    where
      pay.STATUS_LOOKUP_CODE <> 'VOIDED'
  ) tbl_pay ON tbl_pay.PInvoice_Id = aia.INVOICE_ID
LEFT JOIN (
Select 
ail.Invoice_Id as LInvoice_Id,
ail.PREPAY_INVOICE_ID as Prepay_Inv_Id,
aia.INVOICE_ID,
aia.INVOICE_NUM,
aia.PO_HEADER_ID,
pha.Segment1,
aia.invoice_amount * Nvl(aia.exchange_rate, 1) as Linked_Invoice_Amount,
aia.AMOUNT_PAID as Linked_Inv_Paid_Amount,
((aia.invoice_amount * Nvl(aia.exchange_rate, 1)) - aia.AMOUNT_PAID) as Linked_Invoice_Diff, 
aia.INVOICE_CURRENCY_CODE as Linked_Invoice_Currency

From AP_INVOICE_LINES_ALL ail
INNER JOIN  AP_INVOICES_ALL aia on ail.Invoice_Id  = aia.INVOICE_ID and aia.APPROVAL_STATUS = 'APPROVED'
Left Join PO_HEADERS_ALL pha ON pha.PO_HEADER_ID = aia.PO_HEADER_ID
Where ail.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
)tbl_prepay ON tbl_prepay.Prepay_Inv_Id = aia.Invoice_Id

Where
aia.INVOICE_TYPE_LOOKUP_CODE = 'PREPAYMENT'
AND aia.invoice_date Between :PREFROMDATE and :PRETODATE
AND xlel.Name =  :ENTITY

Order By
aia.Invoice_Date