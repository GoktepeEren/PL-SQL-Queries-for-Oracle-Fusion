Select

tbl_Prepayment.Company,
tbl_Prepayment.Vendor,
tbl_Prepayment.InvoiceDesc,
tbl_Prepayment.CreationDate,
tbl_Prepayment.InvoiceNum,
tbl_Prepayment.InvoiceDate,
tbl_Prepayment.InvCurrency,
tbl_Prepayment.PaymentCurrency,
tbl_Prepayment.InvoiceAmount,
tbl_Prepayment.AmountPaid,
tbl_Prepayment.AppliedAmount,
(tbl_Prepayment.AmountPaid + tbl_Prepayment.AppliedAmount) as RemainingAmount,
tbl_Prepayment.InvoiceType,
tbl_Prepayment.InvoiceStatus

From
(Select

horg.Name Company,
sup.VENDOR_NAME Vendor,
inhead.INVOICE_ID InvoiceId,
inhead.DESCRIPTION InvoiceDesc,
inhead.CREATION_DATE CreationDate,
inhead.INVOICE_NUM InvoiceNum,
inhead.INVOICE_DATE InvoiceDate,
inhead.INVOICE_CURRENCY_CODE InvCurrency,
inhead.PAYMENT_CURRENCY_CODE PaymentCurrency,
NVL(inhead.INVOICE_AMOUNT, 0) InvoiceAmount,
NVL(inhead.AMOUNT_PAID, 0) AmountPaid,

(Select 
Sum(NVL(inline.Amount, 0))
From AP_INVOICE_LINES_ALL inline
Where inline.PREPAY_INVOICE_ID = inhead.INVOICE_ID 
Group By inhead.INVOICE_ID) AppliedAmount,


Initcap(inhead.INVOICE_TYPE_LOOKUP_CODE) InvoiceType,
Initcap(inhead.APPROVAL_STATUS) InvoiceStatus

From
AP_INVOICES_ALL inhead 
    Inner Join POZ_SUPPLIERS_V sup 
	On sup.VENDOR_ID = inhead.VENDOR_ID
	Inner Join hr_organization_units horg
    ON horg.Organization_Id = inhead.Org_Id
Where INVOICE_TYPE_LOOKUP_CODE = 'PREPAYMENT' and inhead.APPROVAL_STATUS <> 'CANCELLED') tbl_Prepayment

Where tbl_Prepayment.Company IN (:Company) and tbl_Prepayment.InvoiceStatus IN (:Status)

Order By tbl_Prepayment.CreationDate