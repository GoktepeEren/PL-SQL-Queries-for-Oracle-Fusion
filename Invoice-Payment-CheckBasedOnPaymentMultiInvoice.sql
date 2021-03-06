WITH PaymentInvTot
AS(
    Select
    *
    From
    (
        Select apil.Invoice_ID, api_prepay.Invoice_Num MatchedPreNum, paypre.check_number, paypre.check_date, 
        paypre.status_lookup_code, (apil.amount*-1) InvoicePaidAmount , ((apil.amount*-1) * NVL(api_prepay.Exchange_Rate, 1)) InvoicePaidAmountLCur, paypre.amount PaymentAmount, paypre.currency_code
        From AP_Invoice_Lines_All apil 
        Inner Join AP_INVOICES_ALL api_prepay
            Left Join AP_Invoice_Payments_All payinpre
                Left JOIN ap_checks_all paypre
                ON paypre.check_id = payinpre.check_id and paypre.STATUS_LOOKUP_CODE <> 'VOIDED'
            ON api_prepay.Invoice_Id = payinpre.Invoice_Id 
        ON api_prepay.Invoice_Id = apil.PREPAY_INVOICE_ID and api_prepay.Approval_Status <> 'CANCELLED'
        Where apil.LINE_TYPE_LOOKUP_CODE = 'PREPAY'

        Union All

        Select payinx.Invoice_ID, '' MatchedPreNum, payx.check_number, payx.check_date, payx.status_lookup_code,  
        payinx.amount InvoicePaidAmount, (payinx.amount * NVL(payinx.Exchange_Rate, 1)) InvoicePaidAmountLCur, payx.amount PaymentAmount, payx.currency_code
        From AP_Invoice_Payments_All payinx
        Inner JOIN ap_checks_all payx
        ON payx.check_id = payinx.check_id and payx.STATUS_LOOKUP_CODE <> 'VOIDED'
       


    ) Paymentsx
),

InvProjects As(

    Select
    
        InvoProc.Invoice_ID as InvID,
        LISTAGG(Distinct
            Case 
			When InvoProc.Project = 'DoNotUse-La Romana Common' Then 'La Romana Project Common'
			When InvoProc.Project = 'La Romana Common-Old' Then 'La Romana Project Common'
			Else InvoProc.Project
            End, ', ') WITHIN GROUP (ORDER BY InvoProc.Invoice_ID) as Projects
    	
    From
    (
        Select Distinct inheadp.Invoice_ID, vlhead.Segment1 Project From AP_INVOICES_ALL inheadp Inner Join PJF_PROJECTS_ALL_VL vlhead ON inheadp.ATTRIBUTE_NUMBER5 = vlhead.Project_ID
        Union All
        Select Distinct inlinep.Invoice_ID, vlline.Segment1 Project From AP_INVOICE_LINES_ALL inlinep Inner Join PJF_PROJECTS_ALL_VL vlline ON inlinep.PJC_PROJECT_ID = vlline.Project_ID
        Union All
        Select Distinct indistp.Invoice_ID, vldist.Segment1 Project From AP_INVOICE_LINES_ALL indistp Inner Join PJF_PROJECTS_ALL_VL vldist ON indistp.PJC_PROJECT_ID = vldist.Project_ID

    ) InvoProc
    GROUP BY InvoProc.Invoice_ID
)

Select

xlen.Name,
api.Invoice_Num,
(Select inproc.Projects From InvProjects inproc Where inproc.InvID = api.Invoice_ID) as Projectx,
InvoiceCode.Description InvoiceCode,

(Select 
LISTAGG(tblPoEdited.numberPO , ', ') WITHIN GROUP (ORDER BY tblPoEdited.numberPO) 
From
    (Select
        Distinct po.Segment1 as numberPO 
    From AP_Invoice_Lines_All invline
    Inner Join PO_HEADERS_ALL po ON invline.Po_Header_Id = po.Po_Header_Id and invline.Po_Header_Id is not null and invline.Amount > 0
    Where invline.Invoice_Id = api.Invoice_Id) tblPoEdited)  as PO_Numbers,

(Select tax.REP_REGISTRATION_NUMBER From POZ_SUPPLIERS_V pozs 
Inner Join HZ_PARTIES party 
    Left Join ZX_PARTY_TAX_PROFILE tax ON tax.Party_ID = party.Party_ID
ON pozs.Party_ID = party.Party_ID 
Where tax.REP_REGISTRATION_NUMBER is not null and Rownum <= 1 and pozs.Vendor_ID = supp.Vendor_ID) as TaxPayerId,

supp.VENDOR_NAME,
Translate(api.Description, chr(10)||chr(11)||chr(13), '   ') as Description,
api.Approval_Status,
api.Invoice_Type_Lookup_Code,

api.Invoice_Amount,
(api.Invoice_Amount * Nvl(api.Exchange_Rate, 1)) AS Invoice_AmountLC,
NVL(api.Total_Tax_Amount, 0) Total_Tax_Amount,
(NVL(api.Total_Tax_Amount, 0) * Nvl(api.Exchange_Rate, 1)) AS Total_Tax_AmountLC,


(Select NVL(Sum(inlinex.Amount), 0) From AP_Invoice_Lines_All inlinex Where inlinex.LINE_TYPE_LOOKUP_CODE = 'AWT' and inlinex.Invoice_Id = api.Invoice_Id) as WitholdingAmount,

(Select (NVL(Sum(inlinex.Amount), 0) * Nvl(api.Exchange_Rate, 1)) From AP_Invoice_Lines_All inlinex Where inlinex.LINE_TYPE_LOOKUP_CODE = 'AWT' and inlinex.Invoice_Id = api.Invoice_Id) as WitholdingAmountLC,

(Select NVL(Sum(inlinex.TAX_RATE), 0) From AP_Invoice_Lines_All inlinex Where inlinex.LINE_TYPE_LOOKUP_CODE = 'AWT' and inlinex.Invoice_Id = api.Invoice_Id) as WitholdingRate,


Nvl(api.Exchange_Rate, 1) Exchange_Rate,
api.INVOICE_CURRENCY_CODE,
api.PAYMENT_CURRENCY_CODE,  
  
Case api.Payment_Status_Flag 
When 'N' Then 'Not Paid'
When 'Y' Then 'Paid'
Else 'Partial'
End as PaymentStatusFlag,

NVL(api.AMOUNT_PAID, 0) AMOUNT_PAID,

(NVL(api.AMOUNT_PAID, 0) * Nvl(api.Exchange_Rate, 1)) AMOUNT_PAIDLC,


api.Creation_Date as InvoiceCreation,
api.Invoice_Date as InvoiceDate,
api.GL_Date as InvoiceAccountedDate,
(Select psall.due_date From AP_Payment_Schedules_ALL psall Where psall.Invoice_Id = api.Invoice_Id and Rownum <= 1)  as InvoiceTermDate,

Trunc((Select psall.due_date From AP_Payment_Schedules_ALL psall Where psall.Invoice_Id = api.Invoice_Id and Rownum <= 1) - Trunc(SYSDate)) as RemainingDay,

Case When Trunc((Select psall.due_date From AP_Payment_Schedules_ALL psall Where psall.Invoice_Id = api.Invoice_Id and Rownum <= 1)) <= Trunc(SYSDATE)
Then 'Overdue' Else 'Not Due' End as DueDateStatus,

(api.Invoice_Amount - NVL(api.AMOUNT_PAID, 0) + ((Select NVL(Sum(inlinex.Amount), 0) From AP_Invoice_Lines_All inlinex Where inlinex.LINE_TYPE_LOOKUP_CODE = 'AWT' and inlinex.Invoice_Id = api.Invoice_Id))) as RemainingAmountInvCur,

term.Name as Inv_Term_Name,

termdefault.Name as Def_Term_Name,

supsite.PARTY_SITE_NAME as SuppSiteName,

paytotal.MatchedPreNum  as MatchedPrepaymentNumber,
paytotal.check_number  as check_number,
paytotal.check_date as check_date,
paytotal.status_lookup_code  as status_lookup_code,
paytotal.InvoicePaidAmount as Amount,
paytotal.InvoicePaidAmountLCur as AmountLedgerCurrency,
(Select curinv.INVOICE_CURRENCY_CODE From AP_INVOICES_ALL curinv Where curinv.LEGAL_ENTITY_ID = api.LEGAL_ENTITY_ID and curinv.Exchange_Rate is null and Rownum <= 1) as LedgerCurrency,
paytotal.PaymentAmount as PaymentAmount,
paytotal.currency_code as PaymentCurrency



From AP_INVOICES_ALL api
    Left Join PaymentInvTot paytotal
    ON paytotal.Invoice_ID = api.Invoice_ID

Inner Join POZ_SUPPLIERS_V supp ON api.Vendor_Id = supp.Vendor_Id
Inner Join XLE_ENTITY_PROFILES xlen ON api.LEGAL_ENTITY_ID = xlen.LEGAL_ENTITY_ID
Inner Join AP_TERMS_TL term ON term.TERM_ID = api.TERMS_ID And term.LANGUAGE = fnd_Global.Current_Language
Inner Join POZ_SUPPLIER_SITES_V supsite 
    Left Join AP_TERMS_TL termdefault ON termdefault.TERM_ID = supsite.TERMS_ID And termdefault.LANGUAGE = fnd_Global.Current_Language
On supsite.VENDOR_SITE_ID = api.VENDOR_SITE_ID
Left Join FND_VS_VALUES_VL InvoiceCode ON To_Char(InvoiceCode.Value) = To_Char(api.ATTRIBUTE_NUMBER2) and InvoiceCode.Attribute_Category = 'ACM_Invoice_Codes'

Where 1=1
and paytotal.check_date BETWEEN NVL(:FromDate, TO_DATE('22.09.1992','dd.MM.yyyy')) and NVL(:ToDate, TO_DATE('22.09.2092','dd.MM.yyyy'))
And xlen.Name IN (:LegalEntity)
And ((supp.VENDOR_NAME) IN (:VendorName) OR 'All' IN (:VendorName || 'All'))
and supsite.PARTY_SITE_NAME IN (:VendorSite)
and api.Invoice_Type_Lookup_Code IN (:InvoiceType)
and api.Approval_Status <> 'CANCELLED'
And xlen.Name not like 'Ali Acun%'

-- And api.Invoice_Num = 'BTM2021000000022'
Order By api.Invoice_Date DESC