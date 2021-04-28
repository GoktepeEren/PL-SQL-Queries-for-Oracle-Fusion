select 

SIRKET,
CUSTOMER_NAME,
VERGI_NO,
DONEM, 
count( distinct FATURA_NO) BELGE_SAYISI,
sum(TUTAR_TL) TOPLAM_MATRAH 

from (

select 
(SELECT NAME FROM RA_CUST_TRX_TYPES_ALL WHERE CUST_TRX_TYPE_SEQ_ID=rac.CUST_TRX_TYPE_SEQ_ID) DOKUMAN,
TO_CHAR(RAC.TRX_DATE,'YYYY')||TO_CHAR(RAC.TRX_DATE,'MM') DONEM ,
RAC.TRX_DATE FATURA_TARIHI,'AR' Type, 
hzp.party_name Customer_Name, 
ral.customer_trx_id Customer_Number, 
rac.trx_number FATURA_NO, 
ral.extended_amount FATURA_TUTARI, 
case when rac.invoice_currency_code ='TRY' then  ral.extended_amount else ral.extended_amount*rac.exchange_rate end as Tutar_TL,  
rac.invoice_currency_code PARA_BIRIMI, 
hzc.attribute3 VERGI_DAIRESI, 
NVL(hzc.attribute4, (SELECT max(PTP.REP_REGISTRATION_NUMBER) FROM ZX_PARTY_TAX_PROFILE PTP WHERE hzc.party_id  = PTP.PARTY_ID)) VERGI_NO,
(select min(com.NAME) from XLE_ENTITY_PROFILES com where  com.legal_entity_id=rac.legal_entity_id) SIRKET

From ra_customer_trx_all rac, 
ra_customer_trx_lines_all ral, 
hz_cust_accounts hzc, 
hz_parties hzp 

where 
hzc.cust_account_id=rac.bill_to_customer_id 
and rac.customer_trx_id=ral.customer_trx_id 
and hzp.party_id=hzc.party_id 
and ral.line_type='LINE' 
and (rac.ATTRIBUTE_CATEGORY in ('Fatura','invoice','Standart','Credit Memo', 'Invoice') OR (SELECT NAME FROM RA_CUST_TRX_TYPES_ALL WHERE CUST_TRX_TYPE_SEQ_ID=rac.CUST_TRX_TYPE_SEQ_ID) = 'Maestro(Normal)')  
and (rac.ATTRIBUTE5 not like 'IPT%' or rac.ATTRIBUTE5 is null) 
and (case when rac.invoice_currency_code ='TRY' then  ral.extended_amount else ral.extended_amount*rac.exchange_rate end) > 0 
and rac.customer_trx_id not IN (Select rxta.PREVIOUS_CUSTOMER_TRX_ID From ra_customer_trx_all rxta Where rxta.PREVIOUS_CUSTOMER_TRX_ID is not null and  rxta.ATTRIBUTE_CATEGORY = 'Fatura' and TO_CHAR(rxta.TRX_DATE,'YYYY')||TO_CHAR(rxta.TRX_DATE,'MM') =:P_DONEM  ) 
and TO_CHAR(RAC.TRX_DATE,'YYYY')||TO_CHAR(RAC.TRX_DATE,'MM') =:P_DONEM and 
(rac.ATTRIBUTE14 is null or rac.ATTRIBUTE14='') 

union all


SELECT 'BOŞ' DOKUMAN,TO_CHAR(aia.INVOICE_DATE,'YYYY')||TO_CHAR(aia.INVOICE_DATE,'MM') DONEM,aia.INVOICE_DATE FATURA_TARIHI , 'AP' Type, hzp.party_name Customer_Name, aia.vendor_id Customer_Number ,aia.invoice_num FATURA_NO , aia.INVOICE_AMOUNT-aia.TOTAL_TAX_AMOUNT FATURA_TUTARI, abs((case when aia.invoice_currency_code<>'TRY' then (aia.INVOICE_AMOUNT-aia.TOTAL_TAX_AMOUNT)* aia.EXCHANGE_RATE  else aia.INVOICE_AMOUNT-aia.TOTAL_TAX_AMOUNT  end ))Fatura_TL, aia.invoice_currency_code PARA_BIRIMI,

(select min(attribute2) from POZ_SUPPLIER_SITES_ALL_M  where AIA.VENDOR_ID = VENDOR_ID ) VERGI_DAIRESI, 
NVL((select min(attribute3) from POZ_SUPPLIER_SITES_ALL_M  where AIA.VENDOR_ID = VENDOR_ID), (Select Min(REP_REGISTRATION_NUMBER) From ZX_PARTY_TAX_PROFILE Where PS.Party_id = Party_ID and REP_REGISTRATION_NUMBER is not null))  VERGI_NO ,

(select min(com.NAME) from XLE_ENTITY_PROFILES com where  com.legal_entity_id=aia.legal_entity_id) SIRKET

FROM AP_INVOICES_ALL AIA, POZ_SUPPLIERS PS, HZ_PARTIES hzp WHERE AIA.VENDOR_ID= PS.VENDOR_ID and hzp.party_id=ps.party_id  and aia.approval_status not like 'CANCELLED' 
and (case when aia.invoice_currency_code<>'TRY' then (aia.INVOICE_AMOUNT-aia.TOTAL_TAX_AMOUNT)* aia.EXCHANGE_RATE  else aia.INVOICE_AMOUNT-aia.TOTAL_TAX_AMOUNT  end )<0
and  (TO_CHAR(aia.INVOICE_DATE,'YYYY')||TO_CHAR(aia.INVOICE_DATE,'MM') =:P_DONEM) and (aia.ATTRIBUTE8 is null or aia.ATTRIBUTE8='') 
 )  where SIRKET=:P_SIRKET and DOKUMAN<>'Borç Dekontu'
group by  SIRKET,CUSTOMER_NAME, VERGI_NO,DONEM having sum(TUTAR_TL)>:P_TUTAR