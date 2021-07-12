Select

JEntries.LedgerName,
JEntries.BatchName,
JEntries.BatchDescription,
JEntries.BatchStatus,
JEntries.JournalName,
JEntries.JournalDescription,
JEntries.Source,
JEntries.Status,
JEntries.Category,
JEntries.EffectiveDate,
JEntries.Period,
JEntries.PartyName,
JEntries.PartySiteName,
JEntries.LineNumber,
JEntries.LineDescription,
JEntries.SeqNumber,
JEntries.TransNumber,
JEntries.AccountThree,
JEntries.Account,
JEntries.AccountDesc,
JEntries.Currency,
JEntries.AccountedDebit,
JEntries.AccountedCrebit,
(JEntries.AccountedDebit - JEntries.AccountedCrebit) as AccountedBalance,
Sum((JEntries.AccountedDebit - JEntries.AccountedCrebit)) Over (Order By JEntries.EffectiveDate,JEntries.BatchName, JEntries.JournalName, JEntries.LineNumber) as YuruyenAccBalance,
JEntries.EnteredDebit,
JEntries.EnteredCrebit,
(JEntries.EnteredDebit - JEntries.EnteredCrebit) as EnteredBalance,
JEntries.Rate,
JEntries.Project,
JEntries.CREATION_DATE,
JEntries.CREATED_By,
JEntries.CreatedFullName,
JEntries.Task,
JEntries.ExpOrg

From

(Select 

gled.Name as LedgerName,

glb.NAME as BatchName,
Translate(glb.Description, chr(10)||chr(11)||chr(13), '   ') as BatchDescription,
glb.STATUS as BatchStatus,

glh.NAME as JournalName,
Translate(glh.Description, chr(10)||chr(11)||chr(13), '   ') as JournalDescription,
glh.JE_SOURCE as Source,
glh.JE_CATEGORY as Category,

gll.Status as Status,
gll.EFFECTIVE_DATE as EffectiveDate,
gll.PERIOD_NAME as Period,

Case 
-- Faktoring Part
When glh.JE_CATEGORY = 'Bills Receivable' and 
(Select BillType.NAME
From xla_transaction_entities xent
    Inner Join RA_CUSTOMER_TRX_ALL br_trx
        Inner Join ra_cust_trx_types_all BillType
        On BillType.CUST_TRX_TYPE_SEQ_ID = br_trx.CUST_TRX_TYPE_SEQ_ID
    ON xent.SOURCE_ID_INT_1 = br_trx.Customer_Trx_Id 
Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1)  = 'Faktoring' Then  

(Select CustPart.Party_Name
From xla_transaction_entities xent
    Inner Join RA_CUSTOMER_TRX_LINES_ALL lines
        Inner Join RA_CUSTOMER_TRX_ALL br_trx
            Inner Join HZ_CUST_ACCOUNTS cust
                Inner Join HZ_Parties CustPart 
                ON cust.Party_Id = CustPart.Party_ID
            ON br_trx.BILL_TO_CUSTOMER_ID = cust.CUST_ACCOUNT_ID  
        ON lines.BR_REF_Customer_TRX_Id = br_trx.customer_trx_id 
    ON xent.SOURCE_ID_INT_1 = lines.Customer_Trx_Id 
Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1)

-- Personal Party Part
When
((Select 
    Case When xent.Entity_Code = 'AP_INVOICES' Then apin.Vendor_ID Else 1 End 
From xla_transaction_entities xent
    Inner Join AP_INVOICES_ALL apin ON apin.invoice_id = xent.SOURCE_ID_INT_1
Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1) = -10016 or 
(Select Case When xent.Entity_Code = 'AP_PAYMENTS' Then apin.Vendor_ID Else 1 End 
From xla_transaction_entities xent
    Inner Join AP_Checks_ALL apin ON apin.CHECK_ID = xent.SOURCE_ID_INT_1
Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1) = -10016)

Then 

    Case 
    When (Select xent.Entity_Code From xla_transaction_entities xent  Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1) = 'AP_INVOICES' Then
        (Select NVL(Trim(hzpart.Party_Name), 'Person') From xla_transaction_entities xent
            Left Join AP_INVOICES_ALL apin 
                Inner Join HZ_PARTIES hzpart
                ON hzpart.Party_Id = apin.Party_ID
            ON apin.invoice_id = xent.SOURCE_ID_INT_1
        Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1)

    When (Select xent.Entity_Code From xla_transaction_entities xent  Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1) = 'AP_PAYMENTS' Then
    (Select NVL(Trim(chck.Vendor_Name), 'Person')From xla_transaction_entities xent
            Left Join AP_CHECKS_ALL chck 
            ON chck.CHECK_ID = xent.SOURCE_ID_INT_1
        Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1)

    Else 'Person'
    End


-- Customer, Supplier Part
When PartyGen.PartyName is not null and gcc.Segment2 like '196%' and  NVL(perexp.Display_Name,perexpgline.Display_Name) is not null Then NVL(perexp.Display_Name,perexpgline.Display_Name)

When PartyGen.PartyName is not null and gcc.Segment2 like '196%' and  NVL(perexp.Display_Name,perexpgline.Display_Name) is null Then 

(
	Select Distinct To_Char(perexp2.Display_Name)
	From xla_distribution_links xladist
	Inner Join AP_Invoice_Distributions_All apindist 
		Inner Join AP_invoice_lines_all aplinex
			Left Join per_all_people_f peruser2       
                Inner Join PER_PERSON_NAMES_F_V perexp2 ON perexp2.PERSON_ID = peruser2.PERSON_ID and perexp2.Name_Type = 'GLOBAL' 
                and Trunc(sysdate) between Trunc(perexp2.Effective_Start_Date) and Trunc(perexp2.Effective_End_Date)
        	ON aplinex.ATTRIBUTE15 = peruser2.PERSON_Number and Trunc(sysdate) between Trunc(peruser2.Effective_Start_Date) and Trunc(peruser2.Effective_End_Date)
		ON aplinex.INVOICE_ID= apindist.INVOICE_ID AND aplinex.LINE_NUMBER = apindist.DISTRIBUTION_LINE_NUMBER
	ON apindist.Invoice_Distribution_Id = xladist.SOURCE_DISTRIBUTION_ID_NUM_1 and apindist.LINE_TYPE_LOOKUP_CODE = 'ITEM'
	Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num

)

When PartyGen.PartyName is not null and gcc.Segment2 not like '196%' and  NVL(perexp.Display_Name,perexpgline.Display_Name) is null Then PartyGen.PartyName 

When PartyGen.PartyName is null and gcc.Segment2 like '159%' Then  

(
	Select Distinct suppist.Vendor_Name
	From xla_distribution_links xladist
        Inner Join CMR_RCV_DISTRIBUTIONS rcvist
            Inner Join cmr_rcv_events rcvevents
                Inner Join PO_HEADERS_ALL pohist
                    Inner Join POZ_SUPPLIERS_V suppist 
                    ON suppist.Vendor_Id = pohist.Vendor_ID
                ON rcvevents.source_doc_number = pohist.Segment1
            ON rcvevents.ACCOUNTING_EVENT_ID = rcvist.ACCOUNTING_EVENT_ID
        ON rcvist.CMR_SUB_LEDGER_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and xladist.SOURCE_DISTRIBUTION_TYPE = 'RECEIVING'

)

When PartyGen.PartyName is null and gcc.Segment2 like '320%' and glh.JE_SOURCE = 'Receipt Accounting' Then  
(
	Select Distinct suppist.Vendor_Name
	From xla_distribution_links xladist
        Inner Join CMR_RCV_DISTRIBUTIONS rcvist
            Inner Join cmr_rcv_events rcvevents
                Inner Join PO_HEADERS_ALL pohist
                    Inner Join POZ_SUPPLIERS_V suppist 
                    ON suppist.Vendor_Id = pohist.Vendor_ID
                ON rcvevents.source_doc_number = pohist.Segment1
            ON rcvevents.ACCOUNTING_EVENT_ID = rcvist.ACCOUNTING_EVENT_ID
        ON rcvist.CMR_SUB_LEDGER_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num -- and xladist.SOURCE_DISTRIBUTION_TYPE = 'RECEIVING'

)


When PartyGen.PartyName is null and gcc.Segment2 like '336%'  Then  
(
	-- System separate all receivables gl's according to source table. So we need to link with diffrent table 
    Case 
    -- AR_CASH_RECEIPT_HISTORY_ALL CRH
    When (Select Distinct ardist.SOURCE_TABLE From xla_distribution_links xladist 
    Inner Join AR_DISTRIBUTIONS_ALL ardist ON ardist.Line_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and Rownum <= 1) = 'CRH' Then

	(Select NVL(party.Party_Name, 'Non-Party336')
	From xla_distribution_links xladist
        Inner Join AR_DISTRIBUTIONS_ALL ardist
            Inner Join AR_CASH_RECEIPT_HISTORY_ALL cashhist
                Inner Join AR_CASH_RECEIPTS_ALL receipts
                    Inner Join HZ_CUST_ACCOUNTS cust
                        Inner Join HZ_PARTIES party
                        ON party.PARTY_ID = cust.PARTY_ID 
                    ON receipts.PAY_FROM_CUSTOMER = cust.CUST_ACCOUNT_ID
                ON receipts.CASH_RECEIPT_ID = cashhist.CASH_RECEIPT_ID
            On cashhist.CASH_RECEIPT_HISTORY_ID = ardist.SOURCE_ID
        ON ardist.Line_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1 and ardist.SOURCE_TABLE = 'CRH'
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and Rownum <= 1)

     -- AR_RECEIVABLE_APPLICATIONS_ALL  RA
    When (Select Distinct ardist.SOURCE_TABLE From xla_distribution_links xladist 
    Inner Join AR_DISTRIBUTIONS_ALL ardist ON ardist.Line_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and Rownum <= 1) = 'RA' Then

    (Select NVL(party.Party_Name, 'Non-Party336')
	From xla_distribution_links xladist
        Inner Join AR_DISTRIBUTIONS_ALL ardist
            Inner Join AR_RECEIVABLE_APPLICATIONS_ALL  receall
                Inner Join AR_CASH_RECEIPTS_ALL receipts
                    Inner Join HZ_CUST_ACCOUNTS cust
                        Inner Join HZ_PARTIES party
                        ON party.PARTY_ID = cust.PARTY_ID 
                    ON receipts.PAY_FROM_CUSTOMER = cust.CUST_ACCOUNT_ID
                ON receipts.CASH_RECEIPT_ID = receall.CASH_RECEIPT_ID
            On receall.RECEIVABLE_APPLICATION_ID = ardist.SOURCE_ID
        ON ardist.Line_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1 and ardist.SOURCE_TABLE = 'RA'
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and Rownum <= 1)

    Else 'Non-Party336-1'
    End
)

Else
-- 195, 196 Personel No
NVL(Trim(NVL(perexp.Display_Name,perexpgline.Display_Name)), 'Non-PartyName')
End as PartyName,

Case 
-- Faktoring Site Part
When glh.JE_CATEGORY = 'Bills Receivable' and 
(Select BillType.NAME
From xla_transaction_entities xent
    Inner Join RA_CUSTOMER_TRX_ALL br_trx
        Inner Join ra_cust_trx_types_all BillType
        On BillType.CUST_TRX_TYPE_SEQ_ID = br_trx.CUST_TRX_TYPE_SEQ_ID
    ON xent.SOURCE_ID_INT_1 = br_trx.Customer_Trx_Id 
Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1)  = 'Faktoring' Then 

(Select CustSitePart.Party_Site_Name
From xla_transaction_entities xent
    Inner Join RA_CUSTOMER_TRX_LINES_ALL lines
        Inner Join RA_CUSTOMER_TRX_ALL br_trx
            Inner Join hz_cust_site_uses_all cust
               Inner Join hz_cust_acct_sites_all CustSite 
                    Inner Join HZ_Party_sites CustSitePart 
                    ON CustSite.Party_Site_ID = CustSitePart.Party_Site_ID
                ON CustSite.Cust_Acct_Site_Id = cust.Cust_Acct_Site_Id
            ON br_trx.BILL_TO_SITE_USE_ID = cust.Site_Use_ID  
        ON lines.BR_REF_Customer_TRX_Id = br_trx.customer_trx_id 
    ON xent.SOURCE_ID_INT_1 = lines.Customer_Trx_Id 
Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1)

-- Personal Site Party Part
When
((Select 
    Case When xent.Entity_Code = 'AP_INVOICES' Then apin.Vendor_ID Else 1 End 
From xla_transaction_entities xent
    Inner Join AP_INVOICES_ALL apin ON apin.invoice_id = xent.SOURCE_ID_INT_1
Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1) = -10016 or 
(Select Case When xent.Entity_Code = 'AP_PAYMENTS' Then apin.Vendor_ID Else 1 End 
From xla_transaction_entities xent
    Inner Join AP_Checks_ALL apin ON apin.CHECK_ID = xent.SOURCE_ID_INT_1
Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1) = -10016)

Then 'Employee Site'

-- Customer, Supplier Site Part
When PartySiteGen.PartySiteName is not null Then PartySiteGen.PartySiteName

When NVL(perexp.Display_Name,perexpgline.Display_Name) is not null Then 'Employee Site'

When PartySiteGen.PartySiteName is null and gcc.Segment2 like '159%' Then  

(
	Select Distinct suppist.VENDOR_SITE_CODE
	From xla_distribution_links xladist
        Inner Join CMR_RCV_DISTRIBUTIONS rcvist
            Inner Join cmr_rcv_events rcvevents
                Inner Join PO_HEADERS_ALL pohist
                    Inner Join POZ_SUPPLIER_SITES_V suppist 
                    ON suppist.VENDOR_SITE_ID = pohist.VENDOR_SITE_ID
                ON rcvevents.source_doc_number = pohist.Segment1
            ON rcvevents.ACCOUNTING_EVENT_ID = rcvist.ACCOUNTING_EVENT_ID
        ON rcvist.CMR_SUB_LEDGER_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and xladist.SOURCE_DISTRIBUTION_TYPE = 'RECEIVING'
)

When PartySiteGen.PartySiteName is null and gcc.Segment2 like '320%' and glh.JE_SOURCE = 'Receipt Accounting' Then  
(
	Select Distinct suppist.VENDOR_SITE_CODE
	From xla_distribution_links xladist
        Inner Join CMR_RCV_DISTRIBUTIONS rcvist
            Inner Join cmr_rcv_events rcvevents
                Inner Join PO_HEADERS_ALL pohist
                    Inner Join POZ_SUPPLIER_SITES_V suppist 
                    ON suppist.VENDOR_SITE_ID = pohist.VENDOR_SITE_ID
                ON rcvevents.source_doc_number = pohist.Segment1
            ON rcvevents.ACCOUNTING_EVENT_ID = rcvist.ACCOUNTING_EVENT_ID
        ON rcvist.CMR_SUB_LEDGER_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num -- and xladist.SOURCE_DISTRIBUTION_TYPE = 'RECEIVING'

)

When PartySiteGen.PartySiteName is null and gcc.Segment2 like '336%'  Then  
(
	-- System separate all receivables gl's according to source table. So we need to link with diffrent table 
    Case 
    -- AR_CASH_RECEIPT_HISTORY_ALL CRH
    When (Select Distinct ardist.SOURCE_TABLE From xla_distribution_links xladist 
    Inner Join AR_DISTRIBUTIONS_ALL ardist ON ardist.Line_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and Rownum <= 1) = 'CRH' Then

	(Select NVL(partysites.PARTY_SITE_NAME, 'Non-Party336')
	From xla_distribution_links xladist
        Inner Join AR_DISTRIBUTIONS_ALL ardist
            Inner Join AR_CASH_RECEIPT_HISTORY_ALL cashhist
                Inner Join AR_CASH_RECEIPTS_ALL receipts
                    Left Join HZ_CUST_SITE_USES_ALL custsiteuse
                        Inner Join HZ_CUST_ACCT_SITES_ALL siteacct
                            Inner Join HZ_Party_Sites partysites
                            ON partysites.PARTY_SITE_ID = siteacct.PARTY_SITE_ID
                        ON siteacct.CUST_ACCT_SITE_ID = custsiteuse.CUST_ACCT_SITE_ID
                    ON receipts.CUSTOMER_SITE_USE_ID = custsiteuse.SITE_USE_ID
                ON receipts.CASH_RECEIPT_ID = cashhist.CASH_RECEIPT_ID
            On cashhist.CASH_RECEIPT_HISTORY_ID = ardist.SOURCE_ID
        ON ardist.Line_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1 and ardist.SOURCE_TABLE = 'CRH'
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and Rownum <= 1)

     -- AR_RECEIVABLE_APPLICATIONS_ALL  RA
    When (Select Distinct ardist.SOURCE_TABLE From xla_distribution_links xladist 
    Inner Join AR_DISTRIBUTIONS_ALL ardist ON ardist.Line_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and Rownum <= 1) = 'RA' Then

    (Select NVL(partysites.PARTY_SITE_NAME, 'Non-Party336')
	From xla_distribution_links xladist
        Inner Join AR_DISTRIBUTIONS_ALL ardist
            Inner Join AR_RECEIVABLE_APPLICATIONS_ALL  receall
                Inner Join AR_CASH_RECEIPTS_ALL receipts
                    Left Join HZ_CUST_SITE_USES_ALL custsiteuse
                        Inner Join HZ_CUST_ACCT_SITES_ALL siteacct
                            Inner Join HZ_Party_Sites partysites
                            ON partysites.PARTY_SITE_ID = siteacct.PARTY_SITE_ID
                        ON siteacct.CUST_ACCT_SITE_ID = custsiteuse.CUST_ACCT_SITE_ID
                    ON receipts.CUSTOMER_SITE_USE_ID = custsiteuse.SITE_USE_ID
                ON receipts.CASH_RECEIPT_ID = receall.CASH_RECEIPT_ID
            On receall.RECEIVABLE_APPLICATION_ID = ardist.SOURCE_ID
        ON ardist.Line_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1 and ardist.SOURCE_TABLE = 'RA'
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and Rownum <= 1)

    Else 'Non-Party336-1'
    End

)

Else 'Non-PartySiteName'
End as PartySiteName,

gll.JE_LINE_NUM as LineNumber,
Translate(gll.Description, chr(10)||chr(11)||chr(13), '   ') as LineDescription,

Substr(gcc.Segment2,1,3) AccountThree,

gcc.Segment2 as Account,
valAccoutNordist.Description as AccountDesc,

gll.CURRENCY_CODE as Currency,

NVL(gll.ACCOUNTED_DR, 0) as AccountedDebit,
NVL(gll.ACCOUNTED_CR, 0) as AccountedCrebit,

NVL(gll.ENTERED_DR, 0) as EnteredDebit,
NVL(gll.ENTERED_CR, 0) as EnteredCrebit,

gll.CURRENCY_CONVERSION_RATE as Rate,

NVL(NVL(NVL(NVL(projGLlines.Segment1, projGLHeader.Segment1), proj.Segment1), projReceive.Segment1), 'Non-Project') as Project,

gll.CREATION_DATE, 

glh.POSTING_ACCT_SEQ_VALUE as SeqNumber,


(Select * From (Select Distinct xtra.Transaction_Number From XLA_AE_HEADERS xlad
Inner Join XLA_EVENTS xeve 
    Inner Join XLA_TRANSACTION_ENTITIES xtra
    ON xtra.application_id = xeve.application_id and xtra.Entity_Id = xeve.Entity_Id
ON xeve.application_id = xlad.application_id and xeve.event_id = xlad.event_id
Where xlad.AE_HEADER_ID = xlin.AE_HEADER_ID AND xlad.application_id = xlin.application_id and xtra.Transaction_Number is not null ) Where Rownum <= 1)
as TransNumber,

gll.CREATED_By,

per.Display_Name as CreatedFullName,

NVL(NVL(xlin.SR28, proct.Task_Number), 'Non-Task') Task,

NVL(NVL(NVL(horg.Name, horgline.Name), horghead.Name), 'Non-Organization') ExpOrg

From GL_JE_LINES gll
   Inner Join GL_JE_HEADERS glh

        Inner Join GL_JE_BATCHES glb
        ON glb.JE_BATCH_ID = glh.JE_BATCH_ID

        -- GL Header Project
        -- AutoCopy - Manual - Spreadsheet
        Left Join PJF_PROJECTS_ALL_VL projGLHeader
        ON To_Char(glh.Attribute_Number5) = To_Char(projGLHeader.Project_ID)
        Left Join HR_ORGANIZATION_V horghead
        ON glh.ATTRIBUTE_NUMBER4 = horghead.ORGANIZATION_ID  and horghead.CLASSIFICATION_CODE='DEPARTMENT' and horghead.STATUS='A' and horghead.ATTRIBUTE3 like '%Direktörlük%'
        and Trunc(Sysdate) between Trunc(horghead.EFFECTIVE_START_DATE) and Trunc(horghead.EFFECTIVE_END_DATE)
    On glh.JE_HEADER_ID = gll.JE_HEADER_ID

    Inner Join GL_LEDGERS gled
    ON gll.Ledger_Id = gled.Ledger_Id 
        
    Inner Join  GL_CODE_COMBINATIONS gcc
        Inner Join FND_VS_VALUES_B valAccoutordist
			Inner Join FND_VS_VALUES_TL valAccoutNordist
			ON valAccoutordist.Value_Id = valAccoutNordist.Value_Id 
			and valAccoutNordist.LANGUAGE = FND_GLOBAL.Current_Language
		ON valAccoutordist.Value = gcc.Segment2 and valAccoutordist.ATTRIBUTE_CATEGORY = 'ACM_Account'
    ON gll.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID
        
    -- Left Join GL_Import_References import
    --     Left Join XLA_AE_LINES xlin
    --         Left Join (Select * From
    --                         (Select 'S' as TypeX, Supp.Vendor_ID Id, Supp.Vendor_Name PartyName
    --                         From POZ_SUPPLIERS_V Supp
    --                         Union All

    --                         Select 'C' as TypeX, Cust.Cust_Account_Id Id, CustPart.Party_Name PartyName
    --                         From hz_cust_accounts Cust Inner Join HZ_Parties CustPart ON Cust.Party_Id = CustPart.Party_ID)) PartyGen
    --         ON PartyGen.Id = xlin.Party_ID and xlin.Party_Type_Code = PartyGen.TypeX



    --         Left Join (Select * From
    --                         (Select 'S' as TypeX, SuppSite.VENDOR_SITE_ID Id, SuppSite.VENDOR_SITE_CODE PartySiteName
    --                         From POZ_SUPPLIER_SITES_V SuppSite
    --                         Union All
    --                         Select 'C' as TypeX, CustUse.Site_Use_ID Id, CustSitePart.Party_Site_Name PartySiteName
    --                         From hz_cust_site_uses_all CustUse
    --                         Inner Join hz_cust_acct_sites_all CustSite 
    --                              Inner Join HZ_Party_sites CustSitePart ON CustSite.Party_Site_ID = CustSitePart.Party_Site_ID
    --                         ON CustSite.Cust_Acct_Site_Id = CustUse.Cust_Acct_Site_Id)) PartySiteGen
    --         On xlin.Party_Site_ID = PartySiteGen.Id and xlin.Party_Type_Code = PartySiteGen.TypeX
    --         Left Join per_all_people_f peruser       
    --             Inner Join PER_PERSON_NAMES_F_V perexp ON perexp.PERSON_ID = peruser.PERSON_ID and perexp.Name_Type = 'GLOBAL' 
    --             and Trunc(sysdate) between Trunc(perexp.Effective_Start_Date) and Trunc(perexp.Effective_End_Date)
    --         ON xlin.SR13 = peruser.PERSON_Number and Trunc(sysdate) between Trunc(peruser.Effective_Start_Date) and Trunc(peruser.Effective_End_Date)
            
    --         Left Join PJF_PROJECTS_ALL_VL proj
    --         ON To_Char(xlin.SR31) = To_Char(proj.Project_ID)
    --         Left Join PJF_PROJECTS_ALL_VL projReceive
    --         ON TO_CHAR(xlin.SR7) = TO_CHAR(projReceive.Project_ID)
    --         Left Join HR_ORGANIZATION_V horg
    --         ON TO_CHAR(xlin.SR8) = To_Char(horg.ORGANIZATION_ID)  and horg.CLASSIFICATION_CODE='DEPARTMENT' and horg.STATUS='A' and horg.ATTRIBUTE3 like '%Direktörlük%'
    --         and Trunc(Sysdate) between Trunc(horg.EFFECTIVE_START_DATE) and Trunc(horg.EFFECTIVE_END_DATE)
    --     ON xlin.gl_sl_link_table = import.gl_sl_link_table and  xlin.gl_sl_link_id = import.gl_sl_link_id
    -- ON gll.JE_HEADER_ID  = import.JE_HEADER_ID and gll.JE_LINE_NUM = import.JE_LINE_NUM


        Left Join XLA_AE_LINES xlin
            Left Join (Select * From
                            (Select 'S' as TypeX, Supp.Vendor_ID Id, Supp.Vendor_Name PartyName
                            From POZ_SUPPLIERS_V Supp
                            Union All

                            Select 'C' as TypeX, Cust.Cust_Account_Id Id, CustPart.Party_Name PartyName
                            From hz_cust_accounts Cust Inner Join HZ_Parties CustPart ON Cust.Party_Id = CustPart.Party_ID)) PartyGen
            ON PartyGen.Id = xlin.Party_ID and xlin.Party_Type_Code = PartyGen.TypeX



            Left Join (Select * From
                            (Select 'S' as TypeX, SuppSite.VENDOR_SITE_ID Id, SuppSite.VENDOR_SITE_CODE PartySiteName
                            From POZ_SUPPLIER_SITES_V SuppSite
                            Union All
                            Select 'C' as TypeX, CustUse.Site_Use_ID Id, CustSitePart.Party_Site_Name PartySiteName
                            From hz_cust_site_uses_all CustUse
                            Inner Join hz_cust_acct_sites_all CustSite 
                                 Inner Join HZ_Party_sites CustSitePart ON CustSite.Party_Site_ID = CustSitePart.Party_Site_ID
                            ON CustSite.Cust_Acct_Site_Id = CustUse.Cust_Acct_Site_Id)) PartySiteGen
            On xlin.Party_Site_ID = PartySiteGen.Id and xlin.Party_Type_Code = PartySiteGen.TypeX
            Left Join per_all_people_f peruser       
                Inner Join PER_PERSON_NAMES_F_V perexp ON perexp.PERSON_ID = peruser.PERSON_ID and perexp.Name_Type = 'GLOBAL' 
                and Trunc(sysdate) between Trunc(perexp.Effective_Start_Date) and Trunc(perexp.Effective_End_Date)
            ON xlin.SR13 = peruser.PERSON_Number and Trunc(sysdate) between Trunc(peruser.Effective_Start_Date) and Trunc(peruser.Effective_End_Date)
            
            Left Join PJF_PROJECTS_ALL_VL proj
            ON To_Char(xlin.SR31) = To_Char(proj.Project_ID)
            Left Join PJF_PROJECTS_ALL_VL projReceive
            ON TO_CHAR(xlin.SR7) = TO_CHAR(projReceive.Project_ID)
            Left Join HR_ORGANIZATION_V horg
            ON TO_CHAR(xlin.SR8) = To_Char(horg.ORGANIZATION_ID)  and horg.CLASSIFICATION_CODE='DEPARTMENT' and horg.STATUS='A' and horg.ATTRIBUTE3 like '%Direktörlük%'
            and Trunc(Sysdate) between Trunc(horg.EFFECTIVE_START_DATE) and Trunc(horg.EFFECTIVE_END_DATE)
        ON xlin.AE_HEADER_ID = gll.REFERENCE_7 and  xlin.AE_Line_Num = gll.REFERENCE_8
    
    Left Join PER_USERS perus
        Inner Join PER_PERSON_NAMES_F per 
        ON perus.PERSON_ID = per.PERSON_ID and per.Name_Type = 'GLOBAL' and Trunc(Sysdate) between per.EFFECTIVE_START_DATE and per.EFFECTIVE_End_DATE
    ON perus.Username = gll.CREATED_By 
    
    -- GL Lines Project
    Left Join per_all_people_f perusglline       
        Inner Join PER_PERSON_NAMES_F_V perexpgline ON perexpgline.PERSON_ID = perusglline.PERSON_ID and perexpgline.Name_Type = 'GLOBAL' 
        and Trunc(sysdate) between Trunc(perexpgline.Effective_Start_Date) and Trunc(perexpgline.Effective_End_Date)
    ON gll.ATTRIBUTE2 = perusglline.PERSON_Number and Trunc(sysdate) between Trunc(perusglline.Effective_Start_Date) and Trunc(perusglline.Effective_End_Date)
    Left Join PJF_PROJECTS_ALL_VL projGLlines
    ON To_Char(gll.Attribute1) = To_Char(projGLlines.Project_ID)
    Left Join PJF_TASKS_V  proct 
    ON gll.ATTRIBUTE3  = proct.TASK_ID
    Left Join HR_ORGANIZATION_V horgline
    ON gll.ATTRIBUTE6 = horgline.ORGANIZATION_ID  and horgline.CLASSIFICATION_CODE='DEPARTMENT' and horgline.STATUS='A' and horgline.ATTRIBUTE3 like '%Direktörlük%'
    and Trunc(Sysdate) between Trunc(horgline.EFFECTIVE_START_DATE) and Trunc(horgline.EFFECTIVE_END_DATE)
) JEntries

Where  
JEntries.LedgerName IN (:LEDGER)
and JEntries.Status IN (:AccountingStatus)  
and (JEntries.PartyName IN (:Party) OR 'All' IN (:Party || 'All'))
and (JEntries.PartySiteName IN (:PartySiteName) OR 'All' IN (:PartySiteName || 'All'))
and (JEntries.Account IN (:ACCOUNT) OR 'All' IN (:ACCOUNT || 'All'))
And JEntries.EffectiveDate between NVL((:StartDate),TO_DATE('01.01.1999','dd.MM.yyyy')) and NVL((:EndDate),TO_DATE('01.01.2500','dd.MM.yyyy')) 
and (JEntries.Project IN (:Project) OR 'All' IN (:Project || 'All'))

Order By  JEntries.EffectiveDate,JEntries.BatchName, JEntries.JournalName, JEntries.LineNumber