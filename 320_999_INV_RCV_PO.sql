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
JEntries.ReceiptX,
JEntries.POrderNumber,
JEntries.PartyName,
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

When PartyGen.PartyName is null and glh.JE_SOURCE = 'Receipt Accounting' Then  
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
NVL(PartyGen.PartyName, 'Non-PartyName')
End as PartyName,

Case 
When glh.JE_SOURCE <> 'Receipt Accounting'
Then (Select ListAgg(Distinct apinv.Invoice_Num, ', ') within group (order by apinv.Invoice_Num)
	From xla_distribution_links xladist
        Inner Join AP_INVOICE_DISTRIBUTIONS_ALL apdist
            Inner Join AP_INVOICES_ALL apinv
            ON apinv.INVOICE_Id = apdist.INVOICE_Id
        ON apdist.INVOICE_DISTRIBUTION_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num)
Else 
(Select ListAgg(Distinct recinv.INVOICE_NUMBER	 , ', ') within group (order by  recinv.INVOICE_NUMBER )
	From xla_distribution_links xladist
        Inner Join CMR_RCV_DISTRIBUTIONS rcvist
            Inner Join CMR_RCV_EVENTS rcvevents               
                Inner Join CMR_AP_INVOICE_DTLS recinv
                ON recinv.CMR_PO_DISTRIBUTION_ID  = rcvevents.CMR_PO_DISTRIBUTION_ID 
            ON rcvevents.ACCOUNTING_EVENT_ID = rcvist.ACCOUNTING_EVENT_ID
        ON rcvist.CMR_SUB_LEDGER_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num)
End as Invoice_Num,

Case 
When glh.JE_SOURCE <> 'Receipt Accounting' Then
(Select ListAgg(Distinct rcvship.Receipt_Num, ', ') within group (order by rcvship.Receipt_Num)
	From xla_distribution_links xladist
        Inner Join AP_INVOICE_DISTRIBUTIONS_ALL apdist
            Inner Join AP_INVOICE_LINES_ALL apinvline
                Inner Join rcv_transactions rcvnum
                    Inner Join RCV_SHIPMENT_HEADERS rcvship
                    ON rcvship.SHIPMENT_HEADER_ID  = rcvnum.SHIPMENT_HEADER_ID
                ON rcvnum.TRANSACTION_ID = apinvline.RCV_TRANSACTION_ID and rcvnum.DESTINATION_CONTEXT = 'RECEIVING'
            ON apinvline.Invoice_ID = apdist.Invoice_ID and apinvline.LINE_NUMBER = apdist.INVOICE_LINE_NUMBER 
        ON apdist.INVOICE_DISTRIBUTION_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num)
Else 
(Select ListAgg(Distinct rcvevents.SLA_TRANSACTION_NUMBER, ', ') within group (order by rcvevents.SLA_TRANSACTION_NUMBER)
	From xla_distribution_links xladist
        Inner Join CMR_RCV_DISTRIBUTIONS rcvist
            Inner Join cmr_rcv_events rcvevents
            ON rcvevents.ACCOUNTING_EVENT_ID = rcvist.ACCOUNTING_EVENT_ID and rcvevents.ENTITY_CODE = 'RECEIVING'
        ON rcvist.CMR_SUB_LEDGER_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num)
End as ReceiptX,


Case
When glh.JE_SOURCE <> 'Receipt Accounting' Then 
(Select ListAgg(Distinct poh.SEGMENT1, ', ') within group (order by poh.SEGMENT1)
	From xla_distribution_links xladist
        Inner Join AP_INVOICE_DISTRIBUTIONS_ALL apdist
            Inner Join AP_INVOICE_LINES_ALL apinvline
                Inner Join PO_HEADERS_ALL poh
                ON poh.PO_HEADER_ID = apinvline.PO_HEADER_ID
            ON apinvline.Invoice_ID = apdist.Invoice_ID and apinvline.LINE_NUMBER = apdist.INVOICE_LINE_NUMBER 
        ON apdist.INVOICE_DISTRIBUTION_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num)
Else 
(Select ListAgg(Distinct rcvevents.SOURCE_DOC_NUMBER, ', ') within group (order by  rcvevents.SOURCE_DOC_NUMBER)
	From xla_distribution_links xladist
        Inner Join CMR_RCV_DISTRIBUTIONS rcvist
            Inner Join cmr_rcv_events rcvevents
            ON rcvevents.ACCOUNTING_EVENT_ID = rcvist.ACCOUNTING_EVENT_ID and rcvevents.ENTITY_CODE = 'RECEIVING'
        ON rcvist.CMR_SUB_LEDGER_ID  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num)
End as POrderNumber,

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
JEntries.LedgerName like 'DO0%'
and JEntries.LedgerName not like '%_USD'
and JEntries.LedgerName IN (:Company)
and JEntries.Status IN (:AccountingStatus)  
and (JEntries.PartyName IN (:Party) OR 'All' IN (:Party || 'All'))
and (JEntries.Account = '320.001.001.999')
And JEntries.EffectiveDate between NVL((:StartDate),TO_DATE('01.01.1999','dd.MM.yyyy')) and NVL((:EndDate),TO_DATE('01.01.2500','dd.MM.yyyy')) 


Order By  JEntries.EffectiveDate, JEntries.BatchName, JEntries.JournalName, JEntries.LineNumber