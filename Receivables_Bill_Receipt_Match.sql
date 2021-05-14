With TrxDist 
As (Select Distinct trxdist.Customer_Trx_Id TrxId, trxdist.GL_Date AccountingDate From RA_CUST_TRX_LINE_GL_DIST_ALL trxdist),
CashReceiptH
As (Select Distinct cashrec.CASH_RECEIPT_ID CashRecID, cashrec.GL_Date AccountingDate From AR_CASH_RECEIPT_HISTORY_ALL cashrec)

Select

horg.Name as Company,

party.Party_Name,
partysites.PARTY_SITE_NAME,

rtrx.TRX_NUMBER,
rtrx.TRX_DATE,
trxdistri.AccountingDate,
billtype.NAME TypeBill,
rtrx.TRX_CLASS,
rtrx.COMMENTS,

(Select Sum(trxLines.LINE_RECOVERABLE) From RA_CUSTOMER_TRX_LINES_ALL  trxLines Where trxLines.LINE_TYPE = 'LINE' and trxLines.CUSTOMER_TRX_ID = rtrx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID ) as FaturaTutari,

(Select Sum(trxLines.Tax_RECOVERABLE) From RA_CUSTOMER_TRX_LINES_ALL  trxLines Where trxLines.LINE_TYPE = 'LINE' and trxLines.CUSTOMER_TRX_ID = rtrx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID ) as KDVTutari,

(Select Sum(trxLines.LINE_RECOVERABLE + trxLines.Tax_RECOVERABLE) From RA_CUSTOMER_TRX_LINES_ALL  trxLines Where trxLines.LINE_TYPE = 'LINE' and trxLines.CUSTOMER_TRX_ID = rtrx.CUSTOMER_TRX_ID Group By trxLines.CUSTOMER_TRX_ID ) as ToplamTutar,

rtrx.EXCHANGE_RATE Kur,

rtrx.INVOICE_CURRENCY_CODE,
rtrx.ATTRIBUTE_CATEGORY,
rtrx.ATTRIBUTE5 as EFaturaNo,
rtrx.ATTRIBUTE6 as Gonder,


CashReceiptHis.AccountingDate ReceiptAccountingDate, 
arapp.APPLICATION_TYPE,
arapp.STATUS,
arapp.LINE_APPLIED,
arapp.Tax_APPLIED,

arcash.AMOUNT as ReceipAmount,
arcash.RECEIPT_NUMBER,
arcash.RECEIPT_DATE,
arcash.EXCHANGE_RATE, 
arcash.CURRENCY_CODE,
arreceipt.NAME ReceiptMethod,
partyrec.Party_Name ReceiptCustomer,
(arcash.AMOUNT - (Select Sum(repappx.LINE_APPLIED + repappx.TAX_APPLIED) From AR_RECEIVABLE_APPLICATIONS_ALL repappx Where repappx.CASH_RECEIPT_ID = arcash.CASH_RECEIPT_ID Group By repappx.CASH_RECEIPT_ID)) as RemainingAmount,
arcash.COMMENTS ReceiptsComments

From

RA_CUSTOMER_TRX_ALL rtrx

    Inner Join hr_organization_units horg
    ON horg.Organization_Id = rtrx.Org_Id

    Left Join TrxDist trxdistri
    ON trxdistri.TrxId = rtrx.Customer_Trx_Id 

    Left Join RA_CUST_TRX_TYPES_ALL billtype
    ON billtype.CUST_TRX_TYPE_SEQ_ID = rtrx.CUST_TRX_TYPE_SEQ_ID

    LEFT Join AR_RECEIVABLE_APPLICATIONS_ALL arapp
        LEFT Join AR_CASH_RECEIPTS_ALL arcash
            LEFT Join HZ_CUST_ACCOUNTS custrec
                LEFT Join HZ_PARTIES partyrec
                ON partyrec.PARTY_ID = custrec.PARTY_ID 
            ON arcash.PAY_FROM_CUSTOMER = custrec.CUST_ACCOUNT_ID
            Left Join ar_receipt_methods arreceipt
            ON arcash.RECEIPT_METHOD_ID = arreceipt.RECEIPT_METHOD_ID
            Left Join CashReceiptH CashReceiptHis
            ON CashReceiptHis.CashRecID = arcash.CASH_RECEIPT_ID
        ON arcash.CASH_RECEIPT_ID = arapp.CASH_RECEIPT_ID
    ON arapp.Applied_Customer_TRX_Id = rtrx.CUSTOMER_TRX_ID

    LEFT Join HZ_CUST_ACCOUNTS cust
        LEFT Join HZ_PARTIES party
        ON party.PARTY_ID = cust.PARTY_ID 
    ON rtrx.BILL_TO_CUSTOMER_ID = cust.CUST_ACCOUNT_ID

    LEFT Join HZ_CUST_SITE_USES_ALL custsiteuse
        Inner Join HZ_CUST_ACCT_SITES_ALL siteacct
            Inner Join HZ_Party_Sites partysites
            ON partysites.PARTY_SITE_ID = siteacct.PARTY_SITE_ID
        ON siteacct.CUST_ACCT_SITE_ID = custsiteuse.CUST_ACCT_SITE_ID
    ON rtrx.BILL_TO_SITE_USE_ID = custsiteuse.SITE_USE_ID


Where 
horg.Name IN (:Company)
and (party.Party_Name IN (:Customer) OR 'All' IN (:Customer || 'All'))
And rtrx.TRX_DATE between NVL((:StartDate),TO_DATE('01.01.1999','dd.MM.yyyy')) and NVL((:EndDate),TO_DATE('01.01.2500','dd.MM.yyyy')) 

Order by rtrx.creation_date DESC