With CashReceiptH
As (Select Distinct cashrec.CASH_RECEIPT_ID CashRecID, cashrec.GL_Date AccountingDate From AR_CASH_RECEIPT_HISTORY_ALL cashrec)

Select

horg.Name as Company,
receipts.RECEIPT_NUMBER as ReceiptNumber,
receipts.RECEIPT_DATE as ReceiptDate,
CashReceiptHis.AccountingDate ReceiptAccountingDate,
receipts.Creation_Date as CreationDate,
per.Display_Name as CreatedBy,
Receipts.COMMENTS as Comments,
party.Party_Name,
partysites.PARTY_SITE_NAME,
cust.ACCOUNT_NUMBER AccountNumber,
custsiteuse.LOCATION CustomerSite,
receipts.AMOUNT as Amount,
receipts.Tax_Amount as TaxAmount,
(receipts.AMOUNT - (Select Sum(repappx.LINE_APPLIED + repappx.TAX_APPLIED) From AR_RECEIVABLE_APPLICATIONS_ALL repappx Where repappx.CASH_RECEIPT_ID = receipts.CASH_RECEIPT_ID Group By repappx.CASH_RECEIPT_ID)) as RemainingAmount,
receipts.CURRENCY_CODE as Currency,
bankaccount.BANK_ACCOUNT_NAME as BankAccount,
bankparty.Party_Name as BankName,
receipts.RECON_FLAG as Mutabakat,
(Select Initcap(receipthis.Status) From AR_CASH_RECEIPT_HISTORY_ALL receipthis Where receipthis.CASH_RECEIPT_ID = receipts.CASH_RECEIPT_ID and Rownum <= 1) ReceiptStatus,
Case receipts.STATUS
When  'APP' Then 'Applied/Uygulandı'
When 'NSF' Then 'Nonsufficient Funds/Yetersiz For'
When 'STOP' Then 'Stop Payment/Ödeme Durdurma'
When 'UNAPP' Then 'Unapplied/Uygulanmadı'
When 'CC_CHARGEBACK_REV' Then 'Rev'
When 'REV' Then 'Reversed Receipt/Ters Ödeme'
When 'UNID' Then 'Unidentified / Tanımlanamayan' End  as ReceiptState,
receipts.TYPE as ReceiptType,
methods.NAME as ReceiptMethods,
receipts.ATTRIBUTE_CATEGORY as ReceiptCategory,
receipts.REVERSAL_DATE as ReversalDate,
receipts.REVERSAL_COMMENTS as ReversalCommets,
cekbank.Bank_Name as CekBanka,
receipts.ATTRIBUTE2 as CekSube,
receipts.ATTRIBUTE3 as CekHesap,
receipts.ATTRIBUTE4 as AsılBorclu,
receipts.ATTRIBUTE5 as MakbuzNo,
receipts.ATTRIBUTE6 as FaktoringIslemNo,
receipts.ATTRIBUTE10 as DETAY1,
receipts.ATTRIBUTE13 as DETAY2

From AR_CASH_RECEIPTS_ALL receipts

    Inner Join hr_organization_units horg
    ON horg.Organization_Id = receipts.Org_Id

    Left Join CashReceiptH CashReceiptHis
    ON CashReceiptHis.CashRecID = receipts.CASH_RECEIPT_ID

    Left Join HZ_CUST_ACCOUNTS cust
        LEFT Join HZ_PARTIES party
        ON party.PARTY_ID = cust.PARTY_ID 
    ON receipts.PAY_FROM_CUSTOMER = cust.CUST_ACCOUNT_ID

    Left Join HZ_CUST_SITE_USES_ALL custsiteuse
        Inner Join HZ_CUST_ACCT_SITES_ALL siteacct
            Inner Join HZ_Party_Sites partysites
            ON partysites.PARTY_SITE_ID = siteacct.PARTY_SITE_ID
        ON siteacct.CUST_ACCT_SITE_ID = custsiteuse.CUST_ACCT_SITE_ID
    ON receipts.CUSTOMER_SITE_USE_ID = custsiteuse.SITE_USE_ID

    Left Join AR_RECEIPT_METHODS methods
    ON methods.RECEIPT_METHOD_ID = receipts.RECEIPT_METHOD_ID

    Left Join CE_INDEX_BANKS cekbank
    ON To_Char(cekbank.Bank_Party_Id) = receipts.ATTRIBUTE1

    Left Join PER_USERS perus
         Inner Join PER_PERSON_NAMES_F per 
        ON perus.PERSON_ID = per.PERSON_ID and per.Name_Type = 'GLOBAL' and Trunc(Sysdate) between per.EFFECTIVE_START_DATE and per.EFFECTIVE_End_DATE
    ON perus.Username = receipts.CREATED_By 

    Left Join ce_bank_acct_uses_all bankaccountuse
        Inner Join ce_bank_accounts bankaccount
            Inner Join hz_parties bankparty
            ON bankparty.Party_Id = bankaccount.Bank_Id
        ON bankaccount.Bank_Account_Id = bankaccountuse.Bank_Account_Id
    ON bankaccountuse.BANK_ACCT_USE_ID = receipts.REMIT_BANK_ACCT_USE_ID

Where 
horg.Name IN (:Company)
and (party.Party_Name IN (:Customer) OR 'All' IN (:Customer || 'All'))
And receipts.Receipt_Date between NVL((:StartDate),TO_DATE('01.01.1999','dd.MM.yyyy')) and NVL((:EndDate),TO_DATE('01.01.2500','dd.MM.yyyy')) 


Order By receipts.Creation_Date DESC