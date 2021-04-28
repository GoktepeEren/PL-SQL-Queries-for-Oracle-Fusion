select 

SIRKET,
CUSTOMER_NAME,
VERGI_NO,
DONEM,
count( DISTINCT FATURA_NO) BELGE_SAYISI,sum( TUTAR_TL) TOPLAM_MATRAH 

from (

select 
'POSTED_FLAG',
TO_CHAR(RAC.TRX_DATE,'YYYY')||TO_CHAR(RAC.TRX_DATE,'MM') DONEM,
RAC.TRX_DATE FATURA_TARIHI,
'AR' Type, 
hzp.party_name Customer_Name,
 ral.customer_trx_id Customer_Number, 
rac.trx_number FATURA_NO, 
ral.extended_amount FATURA_TUTARI, 
abs(case when rac.invoice_currency_code ='TRY' then  ral.extended_amount else  ral.extended_amount*rac.exchange_rate end )as Tutar_TL ,  
rac.invoice_currency_code PARA_BIRIMI, 
hzc.attribute3 VERGI_DAIRESI, 
(SELECT max(PTP.REP_REGISTRATION_NUMBER)
FROM ZX_PARTY_TAX_PROFILE PTP
WHERE  hzc.party_id  = PTP.PARTY_ID ) VERGI_NO ,
(select min(com.NAME) from XLE_ENTITY_PROFILES com where  com.legal_entity_id=rac.legal_entity_id) SIRKET
from 
ra_customer_trx_all rac, 
ra_customer_trx_lines_all ral, 
hz_cust_accounts hzc, 
hz_parties hzp 

where hzc.cust_account_id=rac.bill_to_customer_id 
and rac.customer_trx_id=ral.customer_trx_id 
and hzp.party_id=hzc.party_id 
and ral.line_type='LINE'  
and (rac.ATTRIBUTE5 not like 'IPT%' or rac.ATTRIBUTE5 is null)
and (case when rac.invoice_currency_code ='TRY' then  ral.extended_amount else ral.extended_amount*rac.exchange_rate end ) < 0  
and TO_CHAR(RAC.TRX_DATE,'YYYY')||TO_CHAR(RAC.TRX_DATE,'MM') = :P_DONEM  
and (rac.ATTRIBUTE14 is null or rac.ATTRIBUTE14='')
and rac.customer_trx_id IN (Select rxta.PREVIOUS_CUSTOMER_TRX_ID From ra_customer_trx_all rxta Where rxta.PREVIOUS_CUSTOMER_TRX_ID is not null and rxta.ATTRIBUTE_CATEGORY = 'Fatura' and TO_CHAR(rxta.TRX_DATE,'YYYY')||TO_CHAR(rxta.TRX_DATE,'MM') = :P_DONEM)

union all
SELECT 
-- aia.Invoice_Id UDID,
(select MAX(POSTED_FLAG)  from  AP_INVOICE_DISTRIBUTIONS_ALL where Aia.invoice_id =AP_INVOICE_DISTRIBUTIONS_ALL.invoice_id AND  AP_INVOICE_DISTRIBUTIONS_ALL.LAST_UPDATE_DATE = (select max(AP_INVOICE_DISTRIBUTIONS_ALL.LAST_UPDATE_DATE) BB from  AP_INVOICE_DISTRIBUTIONS_ALL where 
aia.invoice_id =AP_INVOICE_DISTRIBUTIONS_ALL.invoice_id) ) POSTED_FLAG, 
TO_CHAR(aia.INVOICE_DATE,'YYYY')||TO_CHAR(aia.INVOICE_DATE,'MM') DONEM,
aia.INVOICE_DATE FATURA_TARIHI ,
 'AP' Type, 
hzp.party_name Customer_Name, 
aia.vendor_id Customer_Number ,
aia.invoice_num FATURA_NO , 
aia.INVOICE_AMOUNT-aia.TOTAL_TAX_AMOUNT FATURA_TUTARI, 
abs((case when aia.invoice_currency_code<>'TRY' 
then ( aia.INVOICE_AMOUNT - aia.TOTAL_TAX_AMOUNT - 
(Select NVL(Sum(indist.Amount),0)
From AP_INVOICE_DISTRIBUTIONS_ALL indist 
	Inner Join GL_CODE_COMBINATIONS glcode 
		Inner Join FND_VS_VALUES_VL valAccout
		ON valAccout.Value = glcode.Segment2 
    and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
ON indist.DIST_CODE_COMBINATION_ID  = glcode.CODE_COMBINATION_ID
Where valAccout.Value like '689%' and indist.Invoice_Id = aia.Invoice_Id)
)* aia.EXCHANGE_RATE  
else aia.INVOICE_AMOUNT-aia.TOTAL_TAX_AMOUNT - 
(Select NVL(Sum(indist.Amount),0)
From AP_INVOICE_DISTRIBUTIONS_ALL indist 
	Inner Join GL_CODE_COMBINATIONS glcode 
		Inner Join FND_VS_VALUES_VL valAccout
		ON valAccout.Value = glcode.Segment2 
    and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
ON indist.DIST_CODE_COMBINATION_ID  = glcode.CODE_COMBINATION_ID
Where valAccout.Value like '689%' and indist.Invoice_Id = aia.Invoice_Id)  end ))Fatura_TL,
 aia.invoice_currency_code PARA_BIRIMI, 
(select min(attribute2) from POZ_SUPPLIER_SITES_ALL_M  where AIA.VENDOR_ID = VENDOR_ID ) VERGI_DAIRESI, 
(SELECT max(PTP.REP_REGISTRATION_NUMBER)
FROM ZX_PARTY_TAX_PROFILE PTP
WHERE hzp.party_id  = PTP.PARTY_ID ) VERGI_NO ,
(select min(com.NAME) from XLE_ENTITY_PROFILES com where  com.legal_entity_id=aia.legal_entity_id) SIRKET
FROM AP_INVOICES_ALL AIA, POZ_SUPPLIERS PS, HZ_PARTIES hzp 
WHERE AIA.VENDOR_ID= PS.VENDOR_ID and hzp.party_id=ps.party_id  and aia.approval_status not like 'CANCELLED' and (  AIA.ATTRIBUTE6<>'Dekont' or AIA.ATTRIBUTE6 is null ) and  aia.INVOICE_TYPE_LOOKUP_CODE in ('STANDART','Standart','STANDARD','Standard' ) 
 and 


(case when aia.invoice_currency_code<>'TRY' then (aia.INVOICE_AMOUNT-aia.TOTAL_TAX_AMOUNT)* aia.EXCHANGE_RATE  else aia.INVOICE_AMOUNT-aia.TOTAL_TAX_AMOUNT  end )>0
and  (TO_CHAR(aia.INVOICE_DATE,'YYYY')||TO_CHAR(aia.INVOICE_DATE,'MM') = :P_DONEM ) and  (aia.ATTRIBUTE8 is null or  aia.ATTRIBUTE8='' ) and 

(select MAX(POSTED_FLAG)  from  AP_INVOICE_DISTRIBUTIONS_ALL where Aia.invoice_id =AP_INVOICE_DISTRIBUTIONS_ALL.invoice_id AND  AP_INVOICE_DISTRIBUTIONS_ALL.LAST_UPDATE_DATE = (select max(AP_INVOICE_DISTRIBUTIONS_ALL.LAST_UPDATE_DATE) BB from  AP_INVOICE_DISTRIBUTIONS_ALL where 
aia.invoice_id =AP_INVOICE_DISTRIBUTIONS_ALL.invoice_id) )  ='Y'

 )  
where SIRKET = :P_SIRKET
group by SIRKET, CUSTOMER_NAME,VERGI_NO,DONEM  having sum( distinct TUTAR_TL) > :P_TUTAR