Select

*

From 
(
  -- Tedarikçi Kısmı, Supplier Part
  (Select
  *
  From
  (
    (select 
    Rec_type,
    TED_NO,CH_UNV, 
    ISLEM_TAR,
    VADE_TAR,
    ACC_DATE,
    E_FATURA,
    ISLEM_NO, 
    ISLEM_TURU,
    PARA_BIRIMI,
    (TUTAR*-1) TUTAR,
    BORC,
    ALACAK,
    BORC_YB,
    ALACAK_YB,
    SIRKET,
    SIRKETID,
    VENDOR_NAME,
    DST_FLAG POST_FLAG

    from 

    (

    (

    select 
    'AP-Satıcı' AS REC_TYPE,
    (select min(poz.segment1) from poz_suppliers poz where hzp.party_id=poz.party_id) TED_NO,
    NVL(SPL.VENDOR_NAME,HZP.PARTY_NAME) CH_UNV,
    aia.INVOICE_DATE ISLEM_TAR,
    aps.due_date VADE_TAR,
    TO_DATE(TO_CHAR((Select oline.ACCOUNTING_Date From AP_Invoice_Lines_All oline Where Rownum <= 1 and oline.invoice_id = aia.invoice_id ),'YYYY/MM/DD'),'YYYY/MM/DD') ACC_DATE,
    -- '' as ACC_Date,
    aia.ATTRIBUTE4 E_FATURA,	
    cast(aia.invoice_num as CHAR(30))  ISLEM_NO, 
    aia.INVOICE_TYPE_LOOKUP_CODE ISLEM_TURU,
    aia.INVOICE_CURRENCY_CODE PARA_BIRIMI,
    LIN_AMOUNT TUTAR,
    (CASE WHEN AIA.EXCHANGE_RATE_TYPE IS NULL AND LIN_AMOUNT<0 THEN ABS(LIN_AMOUNT) WHEN AIA.EXCHANGE_RATE_TYPE IS NOT NULL AND LIN_AMOUNT<0 THEN ABS(LIN_AMOUNT * AIA.EXCHANGE_RATE) ELSE 0 END )BORC,
    (CASE WHEN AIA.EXCHANGE_RATE_TYPE IS NULL AND LIN_AMOUNT>0 THEN ABS(LIN_AMOUNT) WHEN AIA.EXCHANGE_RATE_TYPE IS NOT NULL  AND LIN_AMOUNT>0 THEN ABS(LIN_AMOUNT * AIA.EXCHANGE_RATE) ELSE 0 END)  ALACAK,
    (CASE WHEN AIA.EXCHANGE_RATE_TYPE IS NOT NULL  AND LIN_AMOUNT <0 THEN ABS(LIN_AMOUNT ) ELSE 0 END ) BORC_YB,
    (CASE WHEN AIA.EXCHANGE_RATE_TYPE IS NOT NULL  AND LIN_AMOUNT >0 THEN ABS(LIN_AMOUNT ) ELSE 0 END) ALACAK_YB,
    (select min(org.NAME) from HR_ALL_ORGANIZATION_UNITS org where  org.Organization_Id=aia.Org_Id) SIRKET,
    aia.Org_Id SIRKETID,
    NVL(SPL.VENDOR_NAME,HZP.PARTY_NAME) VENDOR_NAME ,
    DST_FLAG 
    from 
    (SELECT 
    LNS.INVOICE_ID CNT_INVOICE, SUM(LNS.AMOUNT) LIN_AMOUNT 
    , SUM(CASE WHEN LINE_TYPE_LOOKUP_CODE ='AWT' THEN LNS.AMOUNT ELSE 0 END ) STPJ_AMOUNT 
    FROM AP_INVOICE_LINES_ALL LNS 
    WHERE LNS.LINE_TYPE_LOOKUP_CODE NOT IN ( 'PREPAY','MISCELLANEOUS')
    GROUP BY LNS.INVOICE_ID) LNS_CNT ,
    (SELECT SCH.invoice_id SCH_INVOICE,MIN(due_date) due_date FROM AP_PAYMENT_SCHEDULES_ALL SCH GROUP BY SCH.INVOICE_ID)aps ,
    (select 
    INVOICE_ID DST_INVOICE,MAX(POSTED_FLAG) DST_FLAG FROM AP_INVOICE_DISTRIBUTIONS_ALL GROUP BY INVOICE_ID ) DST,
    AP_INVOICES_ALL aia,
    hz_parties hzp,
    POZ_SUPPLIERS_V SPL
    where hzp.party_id=aia.party_id 
    and aia.invoice_id=aps.SCH_INVOICE 
    and aia.invoice_id=DST.DST_INVOICE 
    AND aia.INVOICE_ID = LNS_CNT.CNT_INVOICE
    and aia.invoice_type_lookup_code<>'PREPAYMENT' 
    and aia.approval_status<>'CANCELLED' 
    AND TRIM(SOURCE) <> 'EMP_CASH_ADVANCE' 
    and SPL.VENDOR_ID(+)=aia.VENDOR_ID 
    --AND DST_FLAG = 'Y'
    --AND invoice_num = 'ACM-01'

    )
    UNION ALL

    (

    select 
    'AP-Satıcı' AS REC_TYPE,
    EXT.ATTRIBUTE2 TED_NO,
    HP.PARTY_NAME CH_UNV,
    EXT.TRANSACTION_DATE ISLEM_TAR,
    EXT.VALUE_DATE VADE_TAR,
     TO_DATE(TO_CHAR((Select exacc.Creation_Date From ce_recon_history exacc Where rownum <= 1 and exacc.RECON_HISTORY_ID = ext.RECON_HISTORY_ID),'YYYY/MM/DD'),'YYYY/MM/DD') ACC_DATE,
    -- '' as ACC_Date,
    ' ' E_FATURA,	
    CAST(EXT.TRANSACTION_ID AS CHAR(20)) ISLEM_NO, 
    'Ext. İade' ISLEM_TURU,
    EXT.CURRENCY_CODE PARA_BIRIMI,
    EXT.AMOUNT  TUTAR,
    (CASE WHEN EXT.BANK_CONVERSION_RATE_TYPE IS NULL AND EXT.AMOUNT < 0 THEN EXT.AMOUNT * -1
    WHEN EXT.BANK_CONVERSION_RATE_TYPE	 IS NOT NULL AND EXT.AMOUNT < 0 THEN (EXT.AMOUNT * BANK_CONVERSION_RATE) * -1  ELSE 0 END )BORC,
    (CASE WHEN  EXT.BANK_CONVERSION_RATE_TYPE IS NULL AND EXT.AMOUNT > 0 THEN EXT.AMOUNT  
    WHEN  EXT.BANK_CONVERSION_RATE_TYPE IS NOT NULL AND EXT.AMOUNT > 0 THEN (EXT.AMOUNT * BANK_CONVERSION_RATE)  ELSE 0 END ) ALACAK,
    CASE WHEN  EXT.BANK_CONVERSION_RATE_TYPE IS NOT NULL AND EXT.AMOUNT < 0 THEN EXT.AMOUNT * -1 ELSE 0 END  BORC_YB,
    CASE WHEN  EXT.BANK_CONVERSION_RATE_TYPE IS NOT NULL AND EXT.AMOUNT > 0 THEN EXT.AMOUNT  ELSE 0 END  ALACAK_YB,
    (select min(org.NAME) from HR_ALL_ORGANIZATION_UNITS org where  org.Organization_Id = EXT.Business_Unit_Id) SIRKET,
    EXT.Business_Unit_Id SIRKETID,
    HP.PARTY_NAME VENDOR_NAME ,
    ACCOUNTING_FLAG DST_FLAG 
    FROM CE_EXTERNAL_TRANSACTIONS EXT 
    ,hz_parties HP , per_users  PU 
    ,GL_CODE_COMBINATIONS CC
    where HP.PARTY_TYPE = 'PERSON' AND HP.USER_GUID=PU.USER_GUID
    AND PU.USERNAME = EXT.ATTRIBUTE2  
    --AND EXT.TRANSACTION_ID=93046 
    AND CC.CODE_COMBINATION_ID = EXT.OFFSET_CCID 
    AND CC.SEGMENT2 = '195.001.001.001' 


    )
    union all
    -- Avanslar için GL Fişinden Personel ' ya göre bakiye getiriyor.
    (
    SELECT 
    'GL-Manual' REC_TYPE,
    perusglline.PERSON_Number as TED_NO,
    perexpgline.Display_Name as CH_UNV,
    gll.EFFECTIVE_DATE as  ISLEM_TAR,
    gll.EFFECTIVE_DATE as  VADE_TAR,
    gll.EFFECTIVE_DATE as ACC_DATE,
    ' ' as  E_FATURA,	
    To_Char(glh.NAME) as ISLEM_NO, 
    'Muh. Fişi'  as ISLEM_TURU,
    gll.CURRENCY_CODE as PARA_BIRIMI,
    NVL(gll.ENTERED_CR, 0)  TUTAR,
    NVL(gll.ACCOUNTED_DR, 0) as BORC,
    NVL(gll.ACCOUNTED_CR, 0) as ALACAK,
    CASE WHEN  gll.CURRENCY_CONVERSION_RATE <> 1  THEN NVL(gll.ENTERED_DR, 0) ELSE 0 END  BORC_YB,
    CASE WHEN  gll.CURRENCY_CONVERSION_RATE <> 1  THEN NVL(gll.ENTERED_CR, 0) ELSE 0 END  ALACAK_YB,
    CAST(horg.NAME AS VARCHAR2(255)) as SIRKET, 
    horg.ORGANIZATION_ID as SIRKETID,
    perexpgline.Display_Name as VENDOR_NAME ,
    Case When gll.Status = 'P' Then 'Y' Else 'N' END as DST_FLAG


    From GL_JE_LINES gll
        Inner Join GL_LEDGERS gled
            Inner Join HR_OPERATING_UNITS horg
            ON horg.SET_OF_BOOKS_ID = gled.Ledger_Id
        ON gll.Ledger_Id = gled.Ledger_Id 

        Inner Join GL_JE_HEADERS glh
        On glh.JE_HEADER_ID = gll.JE_HEADER_ID

        Inner Join  GL_CODE_COMBINATIONS gcc
        ON gll.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID

    -- Employee
        Left Join per_all_people_f perusglline       
            Inner Join PER_PERSON_NAMES_F_V perexpgline ON perexpgline.PERSON_ID = perusglline.PERSON_ID and perexpgline.Name_Type = 'GLOBAL' 
            and Trunc(sysdate) between Trunc(perexpgline.Effective_Start_Date) and Trunc(perexpgline.Effective_End_Date)
        ON gll.ATTRIBUTE2 = perusglline.PERSON_Number and Trunc(sysdate) between Trunc(perusglline.Effective_Start_Date) and Trunc(perusglline.Effective_End_Date)

    Where gcc.Segment2 = '195.001.001.001' 
    and gled.Name not like '%_USD'
    )


    union all 
    (
    select  
    'AP-Satıcı' AS REC_TYPE,
    (select min(poz.segment1) from poz_suppliers poz where aca.party_id=poz.party_id)  TED_NO,
    NVL(SPLS.VENDOR_NAME,ACA.VENDOR_NAME) CH_UNV,
    aca.check_date ISLEM_TAR,
    aca.check_date VADE_TAR,
    TO_DATE(TO_CHAR(aca.CLEARED_DATE,'YYYY/MM/DD'),'YYYY/MM/DD') ACC_DATE,
    -- '' as ACC_Date,
    ' ' E_FATURA,
    cast(aca.check_number as char(30)) ISLEM_NO,
    'Odeme' ISLEM_TURU,
    aca.currency_code PARA_BIRIMI,
    aca.amount*-1 TUTAR,
    (CASE WHEN ACA.EXCHANGE_RATE_TYPE IS NULL AND ACA.AMOUNT*-1<0 THEN ABS(ACA.AMOUNT) WHEN ACA.EXCHANGE_RATE_TYPE IS NOT NULL  AND  ACA.BASE_AMOUNT*-1<0 THEN ABS(ACA.BASE_AMOUNT) ELSE 0 END) BORC,
    (CASE WHEN ACA.EXCHANGE_RATE_TYPE IS NULL AND ACA.AMOUNT*-1>0 THEN ABS(ACA.AMOUNT) WHEN ACA.EXCHANGE_RATE_TYPE IS NOT NULL  AND  ACA.BASE_AMOUNT*-1>0 THEN ABS(ACA.BASE_AMOUNT) ELSE 0 END)  ALACAK ,
    (CASE WHEN ACA.EXCHANGE_RATE_TYPE IS NOT NULL  AND  ACA.AMOUNT*-1 <0 THEN ABS(ACA.AMOUNT) ELSE 0 END) BORC_YB,
    (CASE WHEN ACA.EXCHANGE_RATE_TYPE IS NOT NULL  AND ACA.AMOUNT*-1>0 THEN ABS(ACA.AMOUNT) ELSE 0 END)  ALACAK_YB,
    (select min(org.NAME) from HR_ALL_ORGANIZATION_UNITS org where  org.Organization_Id=aca.Org_Id) SIRKET,
    aca.Org_Id SIRKETID,

    NVL(SPLS.VENDOR_NAME,ACA.VENDOR_NAME) W_VENDOR_NAME ,
    POSTED_FLAG  DST_FLAG
    from 
    ap_checks_all aca ,POZ_SUPPLIERS_V SPLS
    ,(
    SELECT  AL.CHECK_ID,
    AL.POSTED_FLAG 
    FROM  AP_PAYMENT_HISTORY_ALL  AL
    WHERE AL.PAYMENT_HISTORY_ID = (
    SELECT 
    MIN(MX.PAYMENT_HISTORY_ID) KEEP (DENSE_RANK FIRST ORDER BY  MX.CHECK_ID,MX.PAYMENT_HISTORY_ID DESC  ) MX_ID 
    FROM AP_PAYMENT_HISTORY_ALL MX WHERE MX.CHECK_ID = AL.CHECK_ID) 
    ) PST
    WHERE 
    SPLS.VENDOR_ID(+)=aca.VENDOR_ID
    AND PST.CHECK_ID= ACA.CHECK_ID 
    AND VOID_DATE IS NULL 
    )

    ) 

    where
    1=1
    and (Trim(VENDOR_NAME) = Trim(:p_party_name) or LEAST(:p_party_name) IS NULL)
    and ISLEM_TAR>=:p_date_from and ISLEM_TAR<= :p_date_end and SIRKETID=:p_businessunit_id

    ) 

    union all

    (
    select 
    REC_TYPE,
    TED_NO,CH_UNV, 
    min(ISLEM_TAR),
    min(VADE_TAR)
    ,min(ACC_Date),' 'aa,' ' ab, 'Devreden Bakiye',PARA_BIRIMI,sum(TUTAR*-1) as TUTAR,
    sum(BORC)as BORC,sum(ALACAK) as ALACAK,sum(BORC_YB) as BORC_YB,sum(ALACAK_YB) as ALACAK_YB,
    min(SIRKET) SIRKET, min(SIRKETID),vendor_name,DST_FLAG POST_FLAG
    from 

    (

    (
    select 
    'AP-Satıcı' AS REC_TYPE,
    (select min(poz.segment1) from poz_suppliers poz where hzp.party_id=poz.party_id) TED_NO,
    NVL(SPL.VENDOR_NAME,HZP.PARTY_NAME) CH_UNV,
    aia.INVOICE_DATE ISLEM_TAR,
    aps.due_date VADE_TAR,
    TO_DATE(TO_CHAR((Select oline.ACCOUNTING_Date From AP_Invoice_Lines_All oline Where Rownum <= 1 and oline.invoice_id = aia.invoice_id ),'YYYY/MM/DD'),'YYYY/MM/DD') ACC_DATE,
    -- '' as ACC_Date,
    aia.ATTRIBUTE4 E_FATURA,	
    cast(aia.invoice_num as CHAR(30))  ISLEM_NO, 
    aia.INVOICE_TYPE_LOOKUP_CODE ISLEM_TURU,
    aia.INVOICE_CURRENCY_CODE PARA_BIRIMI,
    LIN_AMOUNT TUTAR,
    (CASE WHEN AIA.EXCHANGE_RATE_TYPE IS NULL AND LIN_AMOUNT<0 THEN ABS(LIN_AMOUNT) WHEN AIA.EXCHANGE_RATE_TYPE IS NOT NULL AND LIN_AMOUNT<0 THEN ABS(LIN_AMOUNT * AIA.EXCHANGE_RATE) ELSE 0 END )BORC,
    (CASE WHEN AIA.EXCHANGE_RATE_TYPE IS NULL AND LIN_AMOUNT>0 THEN ABS(LIN_AMOUNT) WHEN AIA.EXCHANGE_RATE_TYPE IS NOT NULL  AND LIN_AMOUNT>0 THEN ABS(LIN_AMOUNT * AIA.EXCHANGE_RATE) ELSE 0 END)  ALACAK,
    (CASE WHEN AIA.EXCHANGE_RATE_TYPE IS NOT NULL  AND LIN_AMOUNT <0 THEN ABS(LIN_AMOUNT ) ELSE 0 END ) BORC_YB,
    (CASE WHEN AIA.EXCHANGE_RATE_TYPE IS NOT NULL  AND LIN_AMOUNT >0 THEN ABS(LIN_AMOUNT ) ELSE 0 END) ALACAK_YB,
    (select min(org.NAME) from HR_ALL_ORGANIZATION_UNITS org where  org.Organization_Id=aia.Org_Id) SIRKET,
    aia.Org_Id SIRKETID,
    NVL(SPL.VENDOR_NAME,HZP.PARTY_NAME) VENDOR_NAME ,
    DST_FLAG 
    from 
    (SELECT 
    LNS.INVOICE_ID CNT_INVOICE, SUM(LNS.AMOUNT) LIN_AMOUNT 
    , SUM(CASE WHEN LINE_TYPE_LOOKUP_CODE ='AWT' THEN LNS.AMOUNT ELSE 0 END ) STPJ_AMOUNT 
    FROM AP_INVOICE_LINES_ALL LNS 
    WHERE  LNS.LINE_TYPE_LOOKUP_CODE NOT IN ( 'PREPAY','MISCELLANEOUS')  
    GROUP BY LNS.INVOICE_ID) LNS_CNT ,
    (SELECT SCH.invoice_id SCH_INVOICE,MIN(due_date) due_date FROM AP_PAYMENT_SCHEDULES_ALL SCH GROUP BY SCH.INVOICE_ID)aps ,
    (select 
    INVOICE_ID DST_INVOICE,MAX(POSTED_FLAG) DST_FLAG FROM AP_INVOICE_DISTRIBUTIONS_ALL GROUP BY INVOICE_ID ) DST,
    AP_INVOICES_ALL aia,hz_parties hzp,
    POZ_SUPPLIERS_V SPL
    where hzp.party_id=aia.party_id 
    and aia.invoice_id=aps.SCH_invoice 
    and aia.invoice_id=DST.DST_invoice 
    and aia.invoice_type_lookup_code<>'PREPAYMENT' 
    and aia.approval_status<>'CANCELLED' 
    AND TRIM(SOURCE) <> 'EMP_CASH_ADVANCE' 
    AND aia.INVOICE_ID = LNS_CNT.CNT_INVOICE 
    and SPL.VENDOR_ID(+)=aia.VENDOR_ID
    --AND DST_FLAG = 'Y'
    )
    UNION ALL

    (

    select 
    'AP-Satıcı' AS REC_TYPE,
    EXT.ATTRIBUTE2 TED_NO,
    HP.PARTY_NAME CH_UNV,
    EXT.TRANSACTION_DATE ISLEM_TAR,
    EXT.VALUE_DATE VADE_TAR,
   TO_DATE(TO_CHAR((Select exacc.Creation_Date From ce_recon_history exacc Where rownum <= 1 and exacc.RECON_HISTORY_ID = ext.RECON_HISTORY_ID),'YYYY/MM/DD'),'YYYY/MM/DD') ACC_DATE,
    -- '' as ACC_Date,
    ' ' E_FATURA,	
    CAST(EXT.TRANSACTION_ID AS CHAR(20)) ISLEM_NO, 
    'Ext. İade' ISLEM_TURU,
    EXT.CURRENCY_CODE PARA_BIRIMI,
    EXT.AMOUNT  TUTAR,
    (CASE WHEN EXT.BANK_CONVERSION_RATE_TYPE IS NULL AND EXT.AMOUNT < 0 THEN EXT.AMOUNT * -1
    WHEN EXT.BANK_CONVERSION_RATE_TYPE	 IS NOT NULL AND EXT.AMOUNT < 0 THEN (EXT.AMOUNT * BANK_CONVERSION_RATE) * -1 ELSE 0 END )BORC,
    (CASE WHEN  EXT.BANK_CONVERSION_RATE_TYPE IS NULL AND EXT.AMOUNT > 0 THEN EXT.AMOUNT  
    WHEN  EXT.BANK_CONVERSION_RATE_TYPE IS NOT NULL AND EXT.AMOUNT > 0 THEN (EXT.AMOUNT * BANK_CONVERSION_RATE)  ELSE 0 END ) ALACAK,
    CASE WHEN  EXT.BANK_CONVERSION_RATE_TYPE IS NOT NULL AND EXT.AMOUNT < 0 THEN EXT.AMOUNT * -1  ELSE 0 END  BORC_YB,
    CASE WHEN  EXT.BANK_CONVERSION_RATE_TYPE IS NOT NULL AND EXT.AMOUNT > 0 THEN EXT.AMOUNT  ELSE 0 END  ALACAK_YB,
    (select min(org.NAME) from HR_ALL_ORGANIZATION_UNITS org where  org.Organization_Id=EXT.Business_Unit_Id) SIRKET,
    EXT.Business_Unit_Id SIRKETID,
    HP.PARTY_NAME VENDOR_NAME ,
    ACCOUNTING_FLAG DST_FLAG 
    FROM CE_EXTERNAL_TRANSACTIONS EXT 
    ,hz_parties HP , per_users  PU 
    ,GL_CODE_COMBINATIONS CC
    where HP.PARTY_TYPE = 'PERSON' AND HP.USER_GUID=PU.USER_GUID
    AND PU.USERNAME = EXT.ATTRIBUTE2  
    --AND EXT.TRANSACTION_ID=93046 
    AND CC.CODE_COMBINATION_ID = EXT.OFFSET_CCID 
    AND CC.SEGMENT2 = '195.001.001.001' 
    )

     union all
    -- Avanslar için GL Fişinden Personel ' ya göre bakiye getiriyor.
    (
    SELECT 
    'GL-Manual' REC_TYPE,
    perusglline.PERSON_Number as TED_NO,
    perexpgline.Display_Name as CH_UNV,
    gll.EFFECTIVE_DATE as  ISLEM_TAR,
    gll.EFFECTIVE_DATE as  VADE_TAR,
    gll.EFFECTIVE_DATE as ACC_DATE,
    ' ' as  E_FATURA,	
    To_Char(glh.NAME) as ISLEM_NO, 
    'Muh. Fişi'  as ISLEM_TURU,
    gll.CURRENCY_CODE as PARA_BIRIMI,
    NVL(gll.ENTERED_CR, 0)  TUTAR,
    NVL(gll.ACCOUNTED_DR, 0) as BORC,
    NVL(gll.ACCOUNTED_CR, 0) as ALACAK,
    CASE WHEN  gll.CURRENCY_CONVERSION_RATE <> 1  THEN NVL(gll.ENTERED_DR, 0) ELSE 0 END  BORC_YB,
    CASE WHEN  gll.CURRENCY_CONVERSION_RATE <> 1  THEN NVL(gll.ENTERED_CR, 0) ELSE 0 END  ALACAK_YB,
    CAST(horg.NAME AS VARCHAR2(255)) as SIRKET, 
    horg.ORGANIZATION_ID as SIRKETID,
    perexpgline.Display_Name as VENDOR_NAME ,
    Case When gll.Status = 'P' Then 'Y' Else 'N' END as DST_FLAG


    From GL_JE_LINES gll
        Inner Join GL_LEDGERS gled
            Inner Join HR_OPERATING_UNITS horg
            ON horg.SET_OF_BOOKS_ID = gled.Ledger_Id
        ON gll.Ledger_Id = gled.Ledger_Id 

        Inner Join GL_JE_HEADERS glh
        On glh.JE_HEADER_ID = gll.JE_HEADER_ID

        Inner Join  GL_CODE_COMBINATIONS gcc
        ON gll.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID

    -- Employee
        Left Join per_all_people_f perusglline       
            Inner Join PER_PERSON_NAMES_F_V perexpgline ON perexpgline.PERSON_ID = perusglline.PERSON_ID and perexpgline.Name_Type = 'GLOBAL' 
            and Trunc(sysdate) between Trunc(perexpgline.Effective_Start_Date) and Trunc(perexpgline.Effective_End_Date)
        ON gll.ATTRIBUTE2 = perusglline.PERSON_Number and Trunc(sysdate) between Trunc(perusglline.Effective_Start_Date) and Trunc(perusglline.Effective_End_Date)

    Where gcc.Segment2 = '195.001.001.001' 
    and gled.Name not like '%_USD'
    )

    union all 

    (
    select  
    'AP-Satıcı' AS REC_TYPE,
    (select min(poz.segment1) from poz_suppliers poz where aca.party_id=poz.party_id)  TED_NO,
    NVL(SPLS.VENDOR_NAME,aca.VENDOR_NAME) CH_UNV,
    aca.check_date ISLEM_TAR,
    aca.check_date VADE_TAR,
    TO_DATE(TO_CHAR(aca.CLEARED_DATE,'YYYY/MM/DD'),'YYYY/MM/DD') ACC_Date,
    -- '' as ACC_Date,
    ' ' E_FATURA,
    cast(aca.check_number as char(30)) ISLEM_NO,
    'Odeme' ISLEM_TURU,
    aca.currency_code PARA_BIRIMI,
    aca.amount*-1 TUTAR,
    (CASE WHEN ACA.EXCHANGE_RATE_TYPE IS NULL AND ACA.AMOUNT*-1<0 THEN ABS(ACA.AMOUNT) WHEN ACA.EXCHANGE_RATE_TYPE IS NOT NULL  AND  ACA.BASE_AMOUNT*-1<0 THEN ABS(ACA.BASE_AMOUNT) ELSE 0 END) BORC,
    (CASE WHEN ACA.EXCHANGE_RATE_TYPE IS NULL AND ACA.AMOUNT*-1>0 THEN ABS(ACA.AMOUNT) WHEN ACA.EXCHANGE_RATE_TYPE IS NOT NULL  AND  ACA.BASE_AMOUNT*-1>0 THEN ABS(ACA.BASE_AMOUNT) ELSE 0 END)  ALACAK ,
    (CASE WHEN ACA.EXCHANGE_RATE_TYPE IS NOT NULL  AND  ACA.AMOUNT*-1 <0 THEN ABS(ACA.AMOUNT) ELSE 0 END) BORC_YB,
    (CASE WHEN ACA.EXCHANGE_RATE_TYPE IS NOT NULL  AND ACA.AMOUNT*-1>0 THEN ABS(ACA.AMOUNT) ELSE 0 END)  ALACAK_YB,
    (select min(org.NAME) from HR_ALL_ORGANIZATION_UNITS org where  org.Organization_Id=aca.Org_Id) SIRKET,
    aca.Org_Id SIRKETID,
    NVL(SPLS.VENDOR_NAME,aca.VENDOR_NAME) W_VENDOR_NAME ,
    ' ' DST_FLAG
    from 
    ap_checks_all aca,POZ_SUPPLIERS_V SPLS
    WHERE 
    SPLS.VENDOR_ID(+)=aca.VENDOR_ID 
    AND VOID_DATE IS NULL  )

    ) 

    where
    (Trim(VENDOR_NAME) = Trim(:p_party_name) or LEAST(:p_party_name) IS NULL)
    and ISLEM_TAR<:p_date_from  and SIRKETID=:p_businessunit_id  
    group by CH_UNV,REC_TYPE,TED_NO,PARA_BIRIMI,VENDOR_NAME,DST_FLAG 



    -- order BY ISLEM_TAR
    )))
Union All

    (
      
    select 
    Rec_Type,
    account_number, 
    account_name,
    trx_date,
    due_date,
    acc_date,
    E_FATURA,
    trx_number,
    class,
    INVOICE_CURRENCY_CODE,
    AMOUNT_DUE_ORIGINAL,
    borc,
    alacak,
    borcyb,
    alacakyb,
    Sirket,
    SIRKETID,
    '' vendor_name,
    '' POST_FLAG
    from (

    select 
    'AR-Musteri' AS Rec_Type,
    c.account_number,
    prt.party_name account_name,
    a.trx_date,
    a.due_date, 
    --'' as ACC_Date,
    TO_DATE(TO_CHAR(A.GL_DATE,'YYYY/MM/DD'),'YYYY/MM/DD')  acc_date,

    (Select efno.ATTRIBUTE5 From RA_CUSTOMER_TRX_ALL efno Where Rownum <= 1 and a.CUSTOMER_TRX_ID = efno.CUSTOMER_TRX_ID) as E_FATURA,
    a.trx_number,
    Case When (a.class = 'CM')
    Then  a.class || (Select  ' - ' || orgdoc.TRX_NUMBER from RA_CUSTOMER_TRX_ALL orgdoc Where orgdoc.CUSTOMER_TRX_ID = (Select cmdoc.PREVIOUS_CUSTOMER_TRX_ID  From RA_CUSTOMER_TRX_ALL cmdoc Where A.CUSTOMER_TRX_ID = cmdoc.CUSTOMER_TRX_ID and rownum <= 1))
    When (a.class = 'PMT') Then 'Tahsilat'
    Else a.class End as class,

    a.INVOICE_CURRENCY_CODE,
    a.AMOUNT_DUE_ORIGINAL,

   Case
    When A.Class <> 'BR' Then 
        CASE WHEN  A.EXCHANGE_RATE_TYPE IS NOT NULL AND A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE>0 THEN ABS(A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE)
        WHEN A.EXCHANGE_RATE_TYPE IS NULL  AND A.AMOUNT_DUE_ORIGINAL>0 THEN  ABS(A.AMOUNT_DUE_ORIGINAL)
        ELSE 0 END 
    Else
        CASE WHEN  A.EXCHANGE_RATE_TYPE IS NOT NULL AND A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE<0 THEN ABS(A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE)
        WHEN A.EXCHANGE_RATE_TYPE IS NULL  AND A.AMOUNT_DUE_ORIGINAL<0 THEN  ABS(A.AMOUNT_DUE_ORIGINAL)
        ELSE 0 END
    End
 BORC,


Case 
    When A.Class <> 'BR' Then
        CASE WHEN A.EXCHANGE_RATE_TYPE IS NOT NULL  AND A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE<0 THEN ABS(A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE)
        WHEN A.EXCHANGE_RATE_TYPE IS NULL  AND A.AMOUNT_DUE_ORIGINAL<0 THEN  ABS(A.AMOUNT_DUE_ORIGINAL)
        ELSE 0 END 
    Else
        CASE WHEN  A.EXCHANGE_RATE_TYPE IS NOT NULL AND A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE>0 THEN ABS(A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE)
        WHEN A.EXCHANGE_RATE_TYPE IS NULL  AND A.AMOUNT_DUE_ORIGINAL>0 THEN  ABS(A.AMOUNT_DUE_ORIGINAL)
        ELSE 0 END 
    End
ALACAK,


Case 
    When A.Class <> 'BR' Then
        CASE WHEN  A.EXCHANGE_RATE_TYPE IS NOT NULL  AND A.AMOUNT_DUE_ORIGINAL>0 THEN ABS(A.AMOUNT_DUE_ORIGINAL)
        ELSE 0 END 
    Else
        CASE WHEN A.EXCHANGE_RATE_TYPE IS NOT NULL  AND A.AMOUNT_DUE_ORIGINAL<0 THEN ABS(A.AMOUNT_DUE_ORIGINAL)
        ELSE 0 END
    End
    
BORCYB,

Case 
    When A.Class <> 'BR' Then
        CASE WHEN A.EXCHANGE_RATE_TYPE IS NOT NULL AND A.AMOUNT_DUE_ORIGINAL<0 THEN ABS(A.AMOUNT_DUE_ORIGINAL)
        ELSE 0 END 
    Else
        CASE WHEN A.EXCHANGE_RATE_TYPE IS NOT NULL AND A.AMOUNT_DUE_ORIGINAL>0 THEN ABS(A.AMOUNT_DUE_ORIGINAL)
        ELSE 0 END 
    End    
ALACAKYB,
    
    CAST(ORG.NAME AS VARCHAR2(255)) sirket,
    ORG.ORGANIZATION_ID SIRKETID,
    -- NVL((select min(c.name) from  AR_CASH_RECEIPTS_ALL b , XLE_ENTITY_PROFILES c  where  a.tRX_NUMBER=b.RECEIPT_NUMBER  and  b.Legal_entity_id=c.Legal_entity_id  )
    -- ,(select min(c.name) from  RA_CUSTOMER_TRX_ALL b , XLE_ENTITY_PROFILES c  where  a.tRX_NUMBER=b.TRX_NUMBER  and  b.Legal_entity_id=c.Legal_entity_id  ) )  sirket,
    
    '' vendor_name,
    '' POST_FLAG

    from 
    ar_payment_schedules_all a, 
    hz_cust_accounts c ,
    hz_parties prt,
    HR_ALL_ORGANIZATION_UNITS  ORG
    where 
    1=1 
    AND ORG.ORGANIZATION_ID = A.ORG_ID 
    AND
    Case
    When A.Class <> 'BR' Then A.CUSTOMER_ID 
    Else 
    (Select br_trx.BILL_TO_CUSTOMER_ID  From
    RA_CUSTOMER_TRX_LINES_ALL lines
    Inner Join RA_CUSTOMER_TRX_ALL br_trx 
    ON lines.BR_REF_Customer_TRX_Id = br_trx.customer_trx_id Where Rownum <= 1 and A.Customer_Trx_Id = lines.Customer_Trx_Id )
    End = C.CUST_ACCOUNT_ID

    and Case
    When A.Class <> 'BR' Then C.PARTY_ID 
    Else 
    (Select cust.party_id  From
    RA_CUSTOMER_TRX_LINES_ALL lines
    Inner Join RA_CUSTOMER_TRX_ALL br_trx
        Inner Join HZ_CUST_ACCOUNTS cust
        ON br_trx.BILL_TO_CUSTOMER_ID = cust.CUST_ACCOUNT_ID  
    ON lines.BR_REF_Customer_TRX_Id = br_trx.customer_trx_id Where Rownum <= 1 and A.Customer_Trx_Id = lines.Customer_Trx_Id )
    End = PRT.PARTY_ID 

    -- Reverse kayıtların gelmemesi için yazıldı
    AND ((A.CASH_RECEIPT_ID is NULL) OR ((Select casRec.status From AR_CASH_RECEIPTS_ALL casRec Where A.CASH_RECEIPT_ID = casRec.CASH_RECEIPT_ID ) <> 'REV'))
    AND TO_DATE(TO_CHAR(A.TRX_DATE,'YYYY/MM/DD'),'YYYY/MM/DD') >= TO_DATE(TO_CHAR(:P_DATE_FROM,'YYYY/MM/DD'),'YYYY/MM/DD')
    AND TO_DATE(TO_CHAR(A.TRX_DATE,'YYYY/MM/DD'),'YYYY/MM/DD') <= TO_DATE(TO_CHAR(:P_DATE_END,'YYYY/MM/DD'),'YYYY/MM/DD')

    UNION ALL 

    select 
    rec_type,
    account_number,
    account_name,
    Max(TRX_DATE) trx_date,
    DUE_DATE,
    Acc_Date,
     '' as E_FATURA,
    TRX_NUMBER,
    CLASS,
    INVOICE_CURRENCY_CODE,
    SUM(AMOUNT_DUE_ORIGINAL) AMOUNT_DUE_ORIGINAL,
    SUM(BORC) BORC,
    SUM(ALACAK) ALACAK,
    SUM(BORCYB) BORCYB,
    SUM(ALACAKYB) ALACAKYB,
    sirket,
    SIRKETID,
    '' vendor_name,
    '' POST_FLAG
    FROM 
    (
    SELECT 
    'AR-Musteri' AS Rec_Type,
    c.account_number,
    prt.party_name account_name,
    TO_DATE(TO_CHAR(:p_date_from,'YYYY/MM/DD'),'YYYY/MM/DD') trx_date ,
    NULL DUE_DATE,
    TO_DATE(TO_CHAR(A.GL_DATE,'YYYY/MM/DD'),'YYYY/MM/DD')  Acc_Date,
    -- '' as ACC_Date,
    NULL TRX_NUMBER,
    CAST('Devir ' AS CHAR(30)) CLASS,
    A.INVOICE_CURRENCY_CODE,
    A.AMOUNT_DUE_ORIGINAL AMOUNT_DUE_ORIGINAL,
    Case
        When A.Class <> 'BR' Then 
            CASE WHEN  A.EXCHANGE_RATE_TYPE IS NOT NULL AND A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE>0 THEN ABS(A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE)
            WHEN A.EXCHANGE_RATE_TYPE IS NULL  AND A.AMOUNT_DUE_ORIGINAL>0 THEN  ABS(A.AMOUNT_DUE_ORIGINAL)
            ELSE 0 END 
        Else
            CASE WHEN  A.EXCHANGE_RATE_TYPE IS NOT NULL AND A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE<0 THEN ABS(A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE)
            WHEN A.EXCHANGE_RATE_TYPE IS NULL  AND A.AMOUNT_DUE_ORIGINAL<0 THEN  ABS(A.AMOUNT_DUE_ORIGINAL)
            ELSE 0 END
        End
    BORC,

    Case 
        When A.Class <> 'BR' Then
            CASE WHEN A.EXCHANGE_RATE_TYPE IS NOT NULL  AND A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE<0 THEN ABS(A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE)
            WHEN A.EXCHANGE_RATE_TYPE IS NULL  AND A.AMOUNT_DUE_ORIGINAL<0 THEN  ABS(A.AMOUNT_DUE_ORIGINAL)
            ELSE 0 END 
        Else
            CASE WHEN  A.EXCHANGE_RATE_TYPE IS NOT NULL AND A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE>0 THEN ABS(A.AMOUNT_DUE_ORIGINAL*EXCHANGE_RATE)
            WHEN A.EXCHANGE_RATE_TYPE IS NULL  AND A.AMOUNT_DUE_ORIGINAL>0 THEN  ABS(A.AMOUNT_DUE_ORIGINAL)
            ELSE 0 END 
        End
    ALACAK,


    Case 
        When A.Class <> 'BR' Then
            CASE WHEN  A.EXCHANGE_RATE_TYPE IS NOT NULL  AND A.AMOUNT_DUE_ORIGINAL>0 THEN ABS(A.AMOUNT_DUE_ORIGINAL)
            ELSE 0 END 
        Else
            CASE WHEN A.EXCHANGE_RATE_TYPE IS NOT NULL  AND A.AMOUNT_DUE_ORIGINAL<0 THEN ABS(A.AMOUNT_DUE_ORIGINAL)
            ELSE 0 END
        End
        
    BORCYB,

    Case 
        When A.Class <> 'BR' Then
            CASE WHEN A.EXCHANGE_RATE_TYPE IS NOT NULL AND A.AMOUNT_DUE_ORIGINAL<0 THEN ABS(A.AMOUNT_DUE_ORIGINAL)
            ELSE 0 END 
        Else
            CASE WHEN A.EXCHANGE_RATE_TYPE IS NOT NULL AND A.AMOUNT_DUE_ORIGINAL>0 THEN ABS(A.AMOUNT_DUE_ORIGINAL)
            ELSE 0 END 
        End    
    ALACAKYB,
    -- NVL((select min(c.name) from  AR_CASH_RECEIPTS_ALL b , XLE_ENTITY_PROFILES c  where  a.tRX_NUMBER=b.RECEIPT_NUMBER  and  b.Legal_entity_id=c.Legal_entity_id  )
    -- ,(select min(c.name) from  RA_CUSTOMER_TRX_ALL b , XLE_ENTITY_PROFILES c  where  a.tRX_NUMBER=b.TRX_NUMBER  and  b.Legal_entity_id=c.Legal_entity_id  ) )  sirket
    CAST(ORG.NAME AS VARCHAR2(255)) sirket,
    ORG.ORGANIZATION_ID SIRKETID
    FROM 
    AR_PAYMENT_SCHEDULES_ALL A, 
    HZ_CUST_ACCOUNTS C ,
    (SELECT PARTY_ID , MAX(PARTY_NAME) PARTY_NAME FROM HZ_PARTIES GROUP BY PARTY_ID ) PRT,
    HR_ALL_ORGANIZATION_UNITS  ORG

    WHERE 
    1=1 
    -- Faktöring
    AND
    (Case
    When A.Class <> 'BR' Then A.CUSTOMER_ID 
    Else 
    (Select br_trx.BILL_TO_CUSTOMER_ID  From
    RA_CUSTOMER_TRX_LINES_ALL lines
    Inner Join RA_CUSTOMER_TRX_ALL br_trx 
    ON lines.BR_REF_Customer_TRX_Id = br_trx.customer_trx_id Where Rownum <= 1 and A.Customer_Trx_Id = lines.Customer_Trx_Id )
    End = C.CUST_ACCOUNT_ID)

    -- Faktöring Alt Müşteri 
    And (Case
    When A.Class <> 'BR' Then C.PARTY_ID 
    Else 
    (Select cust.party_id  From
    RA_CUSTOMER_TRX_LINES_ALL lines
    Inner Join RA_CUSTOMER_TRX_ALL br_trx
        Inner Join HZ_CUST_ACCOUNTS cust
        ON br_trx.BILL_TO_CUSTOMER_ID = cust.CUST_ACCOUNT_ID  
    ON lines.BR_REF_Customer_TRX_Id = br_trx.customer_trx_id Where Rownum <= 1 and A.Customer_Trx_Id = lines.Customer_Trx_Id )
    End = PRT.PARTY_ID)
    
    AND ORG.ORGANIZATION_ID = A.ORG_ID 

    -- Reverse kayıtların gelmemesi için yazıldı
    AND ((A.CASH_RECEIPT_ID is NULL) OR ((Select casRec.status From AR_CASH_RECEIPTS_ALL casRec Where A.CASH_RECEIPT_ID = casRec.CASH_RECEIPT_ID ) <> 'REV'))

    -- PARAMETRE EKRANINDAN SECILEN ORG. TANIMININ ID SINI GONDERIYOR !!
    AND TO_DATE(TO_CHAR(A.TRX_DATE,'YYYY/MM/DD'),'YYYY/MM/DD') < TO_DATE(TO_CHAR(:p_date_from,'YYYY/MM/DD'),'YYYY/MM/DD')
    )DVR
    GROUP BY 
    rec_type,
    account_number,
    account_name,
    DUE_DATE,
    acc_date,
    TRX_NUMBER,
    CLASS,
    INVOICE_CURRENCY_CODE,
    sirket,
    SIRKETID
    ) 
    where 
    1=1  
    AND Trim(account_name) = Trim(:p_party_name) 
    AND SIRKETID = :p_businessunit_id
    -- order by Rec_Type,account_number,INVOICE_CURRENCY_CODE
    )


)

Order By ISLEM_TAR