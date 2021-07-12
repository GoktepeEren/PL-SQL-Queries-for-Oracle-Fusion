Select

xlen.Name,
api.Invoice_Num,

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
NVL(api.Total_Tax_Amount, 0) Total_Tax_Amount,

(Select NVL(Sum(inlinex.Amount), 0) From AP_Invoice_Lines_All inlinex Where inlinex.LINE_TYPE_LOOKUP_CODE = 'AWT' and inlinex.Invoice_Id = api.Invoice_Id) as WitholdingAmount,

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

(Select 
LISTAGG(tblPreEdited.PrepaymentNumbers , ', ') WITHIN GROUP (ORDER BY tblPreEdited.PrepaymentNumbers) 
From
    (Select
        Distinct api_prepay.Invoice_Num as PrepaymentNumbers 
    From AP_Invoice_Lines_All apil 
        Inner Join AP_INVOICES_ALL api_prepay
        ON api_prepay.Invoice_Id = apil.PREPAY_INVOICE_ID and api_prepay.Approval_Status <> 'CANCELLED'
    Where api.Invoice_Id = apil.Invoice_Id and apil.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
    ) tblPreEdited)  as MatchedPrepaymentNumber,


-- (Select 
-- LISTAGG(tblPreCheckEdited.PrepaymentCheckNumbers , ', ') WITHIN GROUP (ORDER BY tblPreCheckEdited.PrepaymentCheckNumbers) 
-- From
--     (Select
--         Distinct pay_prepay.check_number as PrepaymentCheckNumbers 
--     From AP_Invoice_Lines_All apil 
--         Inner Join AP_INVOICES_ALL api_prepay
--             Inner Join AP_Invoice_Payments_All payin_prepay
--                 Inner JOIN ap_checks_all pay_prepay
--                 ON pay_prepay.check_id = payin_prepay.check_id and pay_prepay.STATUS_LOOKUP_CODE <> 'VOIDED'
--             ON api_prepay.Invoice_Id = payin_prepay.Invoice_Id 
--         ON api_prepay.Invoice_Id = apil.PREPAY_INVOICE_ID and api_prepay.Approval_Status <> 'CANCELLED'
--     Where api.Invoice_Id = apil.Invoice_Id and apil.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
--     ) tblPreCheckEdited)  as MatchedPrepaymentCheckNumber,


-- (Select 
-- LISTAGG(tblPreCheckEdited.PrepaymentCurrency , ', ') WITHIN GROUP (ORDER BY tblPreCheckEdited.PrepaymentCurrency) 
-- From
--     (Select
--         Distinct pay_prepay.currency_code as PrepaymentCurrency 
--     From AP_Invoice_Lines_All apil 
--         Inner Join AP_INVOICES_ALL api_prepay
--             Inner Join AP_Invoice_Payments_All payin_prepay
--                 Inner JOIN ap_checks_all pay_prepay
--                 ON pay_prepay.check_id = payin_prepay.check_id and pay_prepay.STATUS_LOOKUP_CODE <> 'VOIDED'
--             ON api_prepay.Invoice_Id = payin_prepay.Invoice_Id 
--         ON api_prepay.Invoice_Id = apil.PREPAY_INVOICE_ID and api_prepay.Approval_Status <> 'CANCELLED'
--     Where api.Invoice_Id = apil.Invoice_Id and apil.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
--     ) tblPreCheckEdited)  as MatchedPrepaymentCurrency,


-- (Select 
-- tblprepaytop.totalamount
-- From 
--     (Select apil.Invoice_Id, (SUM(apil.Amount) * -1) as totalamount 
--     From AP_Invoice_Lines_All apil 
--     Where apil.LINE_TYPE_LOOKUP_CODE = 'PREPAY' and api.Invoice_Id = apil.Invoice_Id
--     Group By apil.Invoice_Id) tblprepaytop) as MatchedPrepaymentTotal,

(Case 
When (Select Count(Distinct pay.check_id) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id) <= 1 
        Then 
        (Select 
        Distinct To_Char(pay.check_number) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id)

When (Select Count(Distinct pay.check_id) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id) >= 2  
        Then 
        (Select 
        LISTAGG(pay.check_number , ', ') WITHIN GROUP (ORDER BY pay.check_number) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id)

Else  

        (Select 
        LISTAGG(tblPreCheckEdited.PrepaymentCheckNumbers , ', ') WITHIN GROUP (ORDER BY tblPreCheckEdited.PrepaymentCheckNumbers) 
        From
            (Select
                Distinct pay_prepay.check_number as PrepaymentCheckNumbers 
            From AP_Invoice_Lines_All apil 
                Inner Join AP_INVOICES_ALL api_prepay
                    Inner Join AP_Invoice_Payments_All payin_prepay
                        Inner JOIN ap_checks_all pay_prepay
                        ON pay_prepay.check_id = payin_prepay.check_id and pay_prepay.STATUS_LOOKUP_CODE <> 'VOIDED'
                    ON api_prepay.Invoice_Id = payin_prepay.Invoice_Id 
                ON api_prepay.Invoice_Id = apil.PREPAY_INVOICE_ID and api_prepay.Approval_Status <> 'CANCELLED'
            Where api.Invoice_Id = apil.Invoice_Id and apil.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
            ) tblPreCheckEdited)
        End) as check_number,


(Case 

    When 
        (Select Count(Distinct pay.check_id) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id) <= 1
    Then
        (Select Distinct To_Char(pay.check_date) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id)

    Else
        (Select LISTAGG((pay.check_number || ' - ' || pay.check_date), ', ') WITHIN GROUP (ORDER BY pay.check_number) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id)
    End) check_date,


(Case 

    When 
       (Select Count(Distinct pay.check_id) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id) <= 1
    Then
        (Select Distinct pay.status_lookup_code 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id)

    Else
       (Select LISTAGG((pay.check_number || ' - ' || pay.status_lookup_code), ', ') WITHIN GROUP (ORDER BY pay.check_number) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id)
    End) status_lookup_code,

-- pay.check_date,
-- pay.status_lookup_code,

Case 
-- When pay.amount is not null Then pay.amount
When (Select Count(Distinct pay.check_id)
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id and Rownum <= 1) is not null  
        Then 
        (Select 
        Sum(payin.amount) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id)
        
When (Select Count(Distinct pay.check_id)
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id and Rownum >= 2) is not null  
        Then 
        (Select 
        Sum(payin.amount) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id)
Else  
(Select 
tblprepaytop.totalamount
From 
    (Select apil.Invoice_Id, (SUM(apil.Amount) * -1) as totalamount 
    From AP_Invoice_Lines_All apil 
    Where apil.LINE_TYPE_LOOKUP_CODE = 'PREPAY' and api.Invoice_Id = apil.Invoice_Id
    Group By apil.Invoice_Id) tblprepaytop) End as amount,


Case 
When (Select Count(Distinct pay.check_id)
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id) <= 1 
        Then 
        (Select 
        Distinct pay.currency_code 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id)

When (Select Count(Distinct pay.check_id) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id)  >= 2  
        Then 
        (Select 
        Distinct LISTAGG(pay.check_number || ' - ' || pay.currency_code, ', ') WITHIN GROUP (ORDER BY pay.check_number) 
        From AP_Invoice_Payments_All payin
            Inner JOIN ap_checks_all pay
            ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
        Where api.Invoice_Id = payin.Invoice_Id)

Else 
(Select 
LISTAGG(tblPreCheckEdited.PrepaymentCurrency , ', ') WITHIN GROUP (ORDER BY tblPreCheckEdited.PrepaymentCurrency) 
From
    (Select
        Distinct pay_prepay.currency_code as PrepaymentCurrency 
    From AP_Invoice_Lines_All apil 
        Inner Join AP_INVOICES_ALL api_prepay
            Inner Join AP_Invoice_Payments_All payin_prepay
                Inner JOIN ap_checks_all pay_prepay
                ON pay_prepay.check_id = payin_prepay.check_id and pay_prepay.STATUS_LOOKUP_CODE <> 'VOIDED'
            ON api_prepay.Invoice_Id = payin_prepay.Invoice_Id 
        ON api_prepay.Invoice_Id = apil.PREPAY_INVOICE_ID and api_prepay.Approval_Status <> 'CANCELLED'
    Where api.Invoice_Id = apil.Invoice_Id and apil.LINE_TYPE_LOOKUP_CODE = 'PREPAY'
    ) tblPreCheckEdited) End as PaymentCurrency

-- pay.bank_account_name


From AP_INVOICES_ALL api
-- Left Join AP_Invoice_Payments_All payin
--     Inner JOIN ap_checks_all pay
--     ON pay.check_id = payin.check_id and pay.STATUS_LOOKUP_CODE <> 'VOIDED'
-- ON api.Invoice_Id = payin.Invoice_Id 

Inner Join POZ_SUPPLIERS_V supp ON api.Vendor_Id = supp.Vendor_Id
Inner Join XLE_ENTITY_PROFILES xlen ON api.LEGAL_ENTITY_ID = xlen.LEGAL_ENTITY_ID
Inner Join AP_TERMS_TL term ON term.TERM_ID = api.TERMS_ID And term.LANGUAGE = fnd_Global.Current_Language
Inner Join POZ_SUPPLIER_SITES_V supsite 
    Left Join AP_TERMS_TL termdefault ON termdefault.TERM_ID = supsite.TERMS_ID And termdefault.LANGUAGE = fnd_Global.Current_Language
On supsite.VENDOR_SITE_ID = api.VENDOR_SITE_ID
Left Join FND_VS_VALUES_VL InvoiceCode ON To_Char(InvoiceCode.Value) = To_Char(api.ATTRIBUTE_NUMBER2) and InvoiceCode.Attribute_Category = 'ACM_Invoice_Codes'

Where 
api.Invoice_Date BETWEEN NVL(:FromDate, TO_DATE('22.09.1992','dd.MM.yyyy')) and NVL(:ToDate, TO_DATE('22.09.2092','dd.MM.yyyy'))
And xlen.Name IN (:LegalEntity)
And (Trim(supp.VENDOR_NAME) IN (:VendorName) OR 'All' IN (:VendorName || 'All'))
and supsite.PARTY_SITE_NAME IN (:VendorSite)
and api.Invoice_Type_Lookup_Code IN (:InvoiceType)
and api.Approval_Status <> 'CANCELLED'
And xlen.Name not like 'Ali Acun%'
Order By api.Invoice_Date DESC