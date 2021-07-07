Select

JEntries.LedgerName,
JEntries.PartyName as Party_Name,
JEntries.Party_Number,
JEntries.Account as Value,
JEntries.Currency,
Sum(JEntries.AccountedDebit) as AccountedDebit,
Sum(JEntries.AccountedCrebit) as AccountedCredit,
Sum(JEntries.AccountedDebit - JEntries.AccountedCrebit) as AccountedBalances,
Sum(JEntries.EnteredDebit)  as EnteredDebit,
Sum(JEntries.EnteredCrebit) as EnteredCredit,
Sum(JEntries.EnteredDebit - JEntries.EnteredCrebit) as EnteredBalances

From

(Select 

gled.Name as LedgerName,

gll.Status as Status,
gll.EFFECTIVE_DATE as EffectiveDate,

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
    -- Get Names Employee From Invoices and Payments
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
        Inner Join rcv_transactions rcvist
            Inner Join PO_HEADERS_ALL pohist
                Inner Join POZ_SUPPLIERS_V suppist 
                ON suppist.Vendor_Id = pohist.Vendor_ID
            ON pohist.Po_Header_Id = rcvist.Po_Header_Id
        ON rcvist.Transaction_Id  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and xladist.SOURCE_DISTRIBUTION_TYPE = 'RECEIVING'

)

When PartyGen.PartyName is null and gcc.Segment2 like '320.001.001.999' and glh.JE_SOURCE = 'Receipt Accounting' Then  
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
-- Faktoring Part
When glh.JE_CATEGORY = 'Bills Receivable' and 
(Select BillType.NAME
From xla_transaction_entities xent
    Inner Join RA_CUSTOMER_TRX_ALL br_trx
        Inner Join ra_cust_trx_types_all BillType
        On BillType.CUST_TRX_TYPE_SEQ_ID = br_trx.CUST_TRX_TYPE_SEQ_ID
    ON xent.SOURCE_ID_INT_1 = br_trx.Customer_Trx_Id 
Where xent.Entity_Id = gll.Reference_5 and Rownum <= 1)  = 'Faktoring' Then  

(Select 'C - ' || CustPart.Party_Number
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
OR (PartyGen.PartyName is not null and gcc.Segment2 like '196%')
OR perexp.Display_Name is not null
OR perexpgline.Display_Name is not null
Then 'EmployeeNumber'

When PartyGen.PartyName is null and gcc.Segment2 like '159%' Then  

(
	Select Distinct ('S - ' || suppist.Segment1)
	From xla_distribution_links xladist
        Inner Join rcv_transactions rcvist
            Inner Join PO_HEADERS_ALL pohist
                Inner Join POZ_SUPPLIERS_V suppist 
                ON suppist.Vendor_Id = pohist.Vendor_ID
            ON pohist.Po_Header_Id = rcvist.Po_Header_Id
        ON rcvist.Transaction_Id  = xladist.SOURCE_DISTRIBUTION_ID_NUM_1
    Where xladist.AE_HEADER_ID = xlin.AE_HEADER_ID and xladist.AE_Line_Num = xlin.AE_Line_Num and xladist.SOURCE_DISTRIBUTION_TYPE = 'RECEIVING'

)



When PartyGen.PartyName is null and gcc.Segment2 like '320.001.001.999' and glh.JE_SOURCE = 'Receipt Accounting' Then  
(
	Select Distinct ('S - ' || suppist.Segment1)
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




-- Personal Party Part
Else NVL(PartyGen.P_Number, 'Non-PartyNumber') End as Party_Number,

gcc.Segment2 as Account,

gll.CURRENCY_CODE as Currency,

NVL(gll.ACCOUNTED_DR, 0) as AccountedDebit,
NVL(gll.ACCOUNTED_CR, 0) as AccountedCrebit,

NVL(gll.ENTERED_DR, 0) as EnteredDebit,
NVL(gll.ENTERED_CR, 0) as EnteredCrebit

From GL_JE_LINES gll
   Inner Join GL_JE_HEADERS glh
    On glh.JE_HEADER_ID = gll.JE_HEADER_ID

    Inner Join GL_LEDGERS gled
    ON gll.Ledger_Id = gled.Ledger_Id 
        
    Inner Join  GL_CODE_COMBINATIONS gcc
    ON gll.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID
        
    Left Join GL_Import_References import
        Left Join XLA_AE_LINES xlin
            Left Join (Select * From
                            (Select 'S' as TypeX, Supp.Vendor_ID Id, ('S - '|| Supp.Segment1) P_Number ,Supp.Vendor_Name PartyName
                            From POZ_SUPPLIERS_V Supp
                            Union All

                            Select 'C' as TypeX, Cust.Cust_Account_Id Id, ('C - '|| CustPart.Party_Number) P_Number, CustPart.Party_Name PartyName
                            From hz_cust_accounts Cust Inner Join HZ_Parties CustPart ON Cust.Party_Id = CustPart.Party_ID)) PartyGen
            ON PartyGen.Id = xlin.Party_ID and xlin.Party_Type_Code = PartyGen.TypeX


            Left Join per_all_people_f peruser       
                Inner Join PER_PERSON_NAMES_F_V perexp ON perexp.PERSON_ID = peruser.PERSON_ID and perexp.Name_Type = 'GLOBAL' 
                and Trunc(sysdate) between Trunc(perexp.Effective_Start_Date) and Trunc(perexp.Effective_End_Date)
            ON xlin.SR13 = peruser.PERSON_Number and Trunc(sysdate) between Trunc(peruser.Effective_Start_Date) and Trunc(peruser.Effective_End_Date)
            
        ON xlin.gl_sl_link_table = import.gl_sl_link_table and  xlin.gl_sl_link_id = import.gl_sl_link_id
    ON gll.JE_HEADER_ID  = import.JE_HEADER_ID and gll.JE_LINE_NUM = import.JE_LINE_NUM
    
    -- GL Lines Project
    Left Join per_all_people_f perusglline       
        Inner Join PER_PERSON_NAMES_F_V perexpgline ON perexpgline.PERSON_ID = perusglline.PERSON_ID and perexpgline.Name_Type = 'GLOBAL' 
        and Trunc(sysdate) between Trunc(perexpgline.Effective_Start_Date) and Trunc(perexpgline.Effective_End_Date)
    ON gll.ATTRIBUTE2 = perusglline.PERSON_Number and Trunc(sysdate) between Trunc(perusglline.Effective_Start_Date) and Trunc(perusglline.Effective_End_Date)


    Where gll.Status IN (:AccountingStat)
    And gll.EFFECTIVE_DATE between NVL((:StartDate),TO_DATE('01.01.1999','dd.MM.yyyy')) and NVL((:EndDate),TO_DATE('01.01.2500','dd.MM.yyyy')) 

) JEntries

Group By JEntries.LedgerName, JEntries.PartyName, JEntries.Party_Number, JEntries.Account, JEntries.Currency
Having JEntries.LedgerName IN (:LedgerNameX)
and (JEntries.PartyName IN (:PartyName) OR 'All' IN (:PartyName || 'All'))
and (JEntries.Account IN (:Account) OR 'All' IN (:Account || 'All'))


Order By JEntries.PartyName,  JEntries.Party_Number, JEntries.Account, JEntries.Currency