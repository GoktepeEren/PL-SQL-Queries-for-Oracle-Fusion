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
JEntries.Invoice_Num,
JEntries.EVENT_CLASS_CODE,
JEntries.TransNumber,
JEntries.PartyName,
JEntries.PartySiteName,
JEntries.LineNumber,
JEntries.LineDescription,
JEntries.AccountThree,
JEntries.Account,
JEntries.AccountDesc,
JEntries.Currency,
JEntries.AccountedDebit,
JEntries.AccountedCrebit,
JEntries.EnteredDebit,
JEntries.EnteredCrebit,
JEntries.Rate,
JEntries.CREATION_DATE,
JEntries.CREATED_By,
JEntries.CreatedFullName

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

When NVL(perexp.Display_Name,perexpgline.Display_Name) is not null Then 'Employee Site'

When PartySiteGen.PartySiteName is null and gcc.Segment2 like '159%' Then  

(
	Select Distinct suppist.VENDOR_SITE_CODE
	From xla_distribution_links xladist
        Inner Join rcv_transactions rcvist
            Inner Join PO_HEADERS_ALL pohist
                Inner Join POZ_SUPPLIER_SITES_V suppist 
                ON suppist.VENDOR_SITE_ID = pohist.VENDOR_SITE_ID
            ON pohist.Po_Header_Id = rcvist.Po_Header_Id
        ON rcvist.Transaction_Id  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and xladist.SOURCE_DISTRIBUTION_TYPE = 'RECEIVING'
)

When PartySiteGen.PartySiteName is null and gcc.Segment2 like '320.001.001.999' and glh.JE_SOURCE = 'Receipt Accounting' Then  
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

-- Customer, Supplier Site Part
When PartySiteGen.PartySiteName is not null Then PartySiteGen.PartySiteName

Else 'Non-PartySiteName'
End as PartySiteName,

(Select aia.Invoice_Num From XLA_DISTRIBUTION_LINKS xlad
    Left Join AP_INVOICES_ALL aia ON aia.INVOICE_ID = xlad.APPLIED_TO_SOURCE_ID_NUM_1
Where xlad.AE_HEADER_ID = xlin.AE_HEADER_ID AND xlad.AE_LINE_NUM = xlin.AE_LINE_NUM AND xlad.EVENT_CLASS_CODE = 'INVOICES' and Rownum <= 1 )
as Invoice_Num,

(Select Initcap(xlad.EVENT_CLASS_CODE) From XLA_DISTRIBUTION_LINKS xlad
Where xlad.AE_HEADER_ID = xlin.AE_HEADER_ID AND xlad.AE_LINE_NUM = xlin.AE_LINE_NUM )
as EVENT_CLASS_CODE,



(Select * From (Select Distinct xtra.Transaction_Number From XLA_AE_HEADERS xlad
Inner Join XLA_EVENTS xeve 
    Inner Join XLA_TRANSACTION_ENTITIES xtra
    ON xtra.application_id = xeve.application_id and xtra.Entity_Id = xeve.Entity_Id
ON xeve.application_id = xlad.application_id and xeve.event_id = xlad.event_id
Where xlad.AE_HEADER_ID = xlin.AE_HEADER_ID AND xlad.application_id = xlin.application_id ) Where Rownum <= 1)
as TransNumber,

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

Nvl(gll.CURRENCY_CONVERSION_RATE, 1) as Rate,

gll.CREATION_DATE, 

gll.CREATED_By,


per.Display_Name as CreatedFullName



From GL_JE_LINES gll
   Inner Join GL_JE_HEADERS glh

        Inner Join GL_JE_BATCHES glb
        ON glb.JE_BATCH_ID = glh.JE_BATCH_ID

        -- GL Header Project
        -- AutoCopy - Manual - Spreadsheet
      
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
        
    Left Join GL_Import_References import
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
            
           
        ON xlin.gl_sl_link_table = import.gl_sl_link_table and  xlin.gl_sl_link_id = import.gl_sl_link_id
    ON gll.JE_HEADER_ID  = import.JE_HEADER_ID and gll.JE_LINE_NUM = import.JE_LINE_NUM
    
    Left Join PER_USERS perus
        Inner Join PER_PERSON_NAMES_F per 
        ON perus.PERSON_ID = per.PERSON_ID and per.Name_Type = 'GLOBAL' and Trunc(Sysdate) between per.EFFECTIVE_START_DATE and per.EFFECTIVE_End_DATE
    ON perus.Username = gll.CREATED_By 
    
    -- GL Lines Project
    Left Join per_all_people_f perusglline       
        Inner Join PER_PERSON_NAMES_F_V perexpgline ON perexpgline.PERSON_ID = perusglline.PERSON_ID and perexpgline.Name_Type = 'GLOBAL' 
        and Trunc(sysdate) between Trunc(perexpgline.Effective_Start_Date) and Trunc(perexpgline.Effective_End_Date)
    ON gll.ATTRIBUTE2 = perusglline.PERSON_Number and Trunc(sysdate) between Trunc(perusglline.Effective_Start_Date) and Trunc(perusglline.Effective_End_Date)


 
) JEntries

Where  
JEntries.LedgerName IN (:LEDGER)
and JEntries.Status IN (:AccountingStatus)  
and (JEntries.PartyName IN (:Party) OR 'All' IN (:Party || 'All'))
and (JEntries.Account IN (:ACCOUNT) OR 'All' IN (:ACCOUNT || 'All'))
And JEntries.EffectiveDate between NVL((:StartDate),TO_DATE('01.01.1999','dd.MM.yyyy')) and NVL((:EndDate),TO_DATE('01.01.2500','dd.MM.yyyy')) 


Order By  JEntries.BatchName, JEntries.JournalName, JEntries.EffectiveDate, JEntries.LineNumber