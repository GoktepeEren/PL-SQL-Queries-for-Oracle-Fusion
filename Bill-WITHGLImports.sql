WITH GLImports
AS (Select Distinct ref5.JE_HEADER_ID headerID, ref5.REFERENCE_5 reference5 From GL_IMPORT_REFERENCES ref5)

Select

ROW_NUMBER() OVER (ORDER BY  trx.TRX_Date, trx.CUSTOMER_TRX_ID) AS SEQ, 


org.Name as Sirket,

trx.CUSTOMER_TRX_ID,

trx.Trx_Number,

Case 
When Length(To_Char(taxprof.REP_REGISTRATION_NUMBER)) >= 11 Then To_Char(taxprof.REP_REGISTRATION_NUMBER) 
Else ''
End TC_Kimlik_No,

Case 
When Length(To_Char(taxprof.REP_REGISTRATION_NUMBER)) <= 10 Then To_Char(taxprof.REP_REGISTRATION_NUMBER) 
Else null 
End Vergi_Kimlik,

party.Party_Name,

trx.TRX_Date,

Substr(trx.ATTRIBUTE5,1,3) as Series,

-- glheader.POSTING_ACCT_SEQ_VALUE as SiraNo,

Substr(trx.ATTRIBUTE5,4,Length(trx.ATTRIBUTE5)) as SiraNo,


'625' as Cinsi,

(Select Sum(trxLines.LINE_RECOVERABLE) From RA_CUSTOMER_TRX_LINES_ALL  trxLines Where trxLines.LINE_TYPE = 'LINE' and trxLines.CUSTOMER_TRX_ID = trx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID ) as Tutari,

(Select  Sum(trxLines.Tax_Rate) From RA_CUSTOMER_TRX_LINES_ALL trxLines Where trxLines.LINE_TYPE = 'TAX' and trxLines.Tax_Rate > 0 and trxLines.CUSTOMER_TRX_ID = trx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID) /
(Select  Count(trxLines.CUSTOMER_TRX_LINE_ID) From RA_CUSTOMER_TRX_LINES_ALL trxLines Where trxLines.LINE_TYPE = 'LINE' and trxLines.CUSTOMER_TRX_ID = trx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID) 
as KDVOrani,


-- Line Total
((Select Sum(trxLines.LINE_RECOVERABLE) From RA_CUSTOMER_TRX_LINES_ALL  trxLines Where trxLines.LINE_TYPE = 'LINE' and trxLines.CUSTOMER_TRX_ID = trx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID ) * 
-- KDV rate / 100
((Select  Sum(trxLines.Tax_Rate) From RA_CUSTOMER_TRX_LINES_ALL trxLines Where trxLines.LINE_TYPE = 'TAX' and trxLines.Tax_Rate > 0 and trxLines.CUSTOMER_TRX_ID = trx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID) /
(Select  Count(trxLines.CUSTOMER_TRX_LINE_ID) From RA_CUSTOMER_TRX_LINES_ALL trxLines Where trxLines.LINE_TYPE = 'LINE' and trxLines.CUSTOMER_TRX_ID = trx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID))  / 100) 
as KDVTutari,

'3/10' as TevkifatOranı,

-- Line Total
((Select Sum(trxLines.LINE_RECOVERABLE) From RA_CUSTOMER_TRX_LINES_ALL  trxLines Where trxLines.LINE_TYPE = 'LINE' and trxLines.CUSTOMER_TRX_ID = trx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID ) * 
-- KDV rate / 100
((Select  Sum(trxLines.Tax_Rate) From RA_CUSTOMER_TRX_LINES_ALL trxLines Where trxLines.LINE_TYPE = 'TAX' and trxLines.Tax_Rate > 0 and trxLines.CUSTOMER_TRX_ID = trx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID) /
(Select  Count(trxLines.CUSTOMER_TRX_LINE_ID) From RA_CUSTOMER_TRX_LINES_ALL trxLines Where trxLines.LINE_TYPE = 'LINE' and trxLines.CUSTOMER_TRX_ID = trx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID))  / 100 * (0.3))   as TevkifatTutari


From


RA_CUSTOMER_TRX_ALL trx

    Inner Join hr_organization_units org
    ON org.Organization_Id = trx.Org_Id

    Left Join HZ_CUST_ACCOUNTS cust
        Left Join HZ_PARTIES party
            Left Join ZX_PARTY_TAX_PROFILE taxprof
            ON party.party_id  = taxprof.PARTY_ID
        ON party.PARTY_ID = cust.PARTY_ID 
    ON trx.BILL_TO_CUSTOMER_ID = cust.CUST_ACCOUNT_ID

    -- Inner Join xla_transaction_entities tranEnt
    --    Inner Join GLImports
    --         Inner Join GL_JE_HEADERS glheader
    --             Inner Join GL_LEDGERS glled
    --             ON glled.Ledger_ID = glheader.Ledger_Id and glled.Name not like '%USD'
    --         ON GLImports.headerID = glheader.JE_HEADER_ID
    --    ON GLImports.reference5 = tranEnt.Entity_Id
    -- ON tranEnt.Source_Id_Int_1 = trx.CUSTOMER_TRX_ID


Where
trx.CUSTOMER_TRX_ID IN (Select Distinct lines.CUSTOMER_TRX_ID From RA_CUSTOMER_TRX_LINES_ALL lines Where lines.TAX_CLASSIFICATION_CODE like '%TVK%' )
and org.Name IN (:OrgName)
and org.Name not like 'TR07%'
And trx.TRX_DATE between NVL((:StartDate),TO_DATE('01.01.1999','dd.MM.yyyy')) and NVL((:EndDate),TO_DATE('01.01.2500','dd.MM.yyyy')) 
and trx.PREVIOUS_CUSTOMER_TRX_ID is null
and trx.CUSTOMER_TRX_ID NOT IN (Select trxp.PREVIOUS_CUSTOMER_TRX_ID From RA_CUSTOMER_TRX_ALL trxp Where trxp.Org_Id = trx.Org_Id and trxp.PREVIOUS_CUSTOMER_TRX_ID is not null)
-- Order By trx.TRX_Date
-- trx.TRX_Number = 'M-X20210004829610'