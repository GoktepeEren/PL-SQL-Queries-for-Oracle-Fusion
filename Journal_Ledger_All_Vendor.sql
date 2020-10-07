Select 

glb.JE_BATCH_ID "Batch Id",
gll.JE_HEADER_ID "Header_Id",
gll.LEDGER_ID "Ledger_Id",
gll.CODE_COMBINATION_ID "Code_Id",
gled.Name "Ledger_Name",
gll.PERIOD_NAME "Period",
glb.NAME "Batch Name",
glb.DESCRIPTION "Batch Description",
glb.STATUS "Batch Status",
gll.EFFECTIVE_DATE "Effective Date",
glh.NAME "Journal Name",
glh.DESCRIPTION "Journal Description",
poz.Vendor_Name as SuppName,
supsite.PARTY_SITE_NAME as SuppSiteName,
glh.JE_SOURCE "Source",
glh.JE_CATEGORY "Category",
gll.JE_LINE_NUM"Line_Number",
gll.DESCRIPTION "Line_Description",
gcc.Segment2 "Account",
valAccoutNordist.Description as AccountDesc,
gll.ENTERED_DR "Entered Debit",
gll.ENTERED_CR "Entered Credit",

Sum(NVL(gll.ENTERED_DR,0) - NVL(gll.ENTERED_CR, 0))OVER(ORDER BY gll.EFFECTIVE_DATE, gll.JE_LINE_NUM) as Entered_Fark ,

gll.ACCOUNTED_DR "Accounted Debit",
gll.ACCOUNTED_CR "Accounted Crebit",

Sum(NVL(gll.ACCOUNTED_DR,0) - NVL(gll.ACCOUNTED_CR,0))OVER(ORDER BY gll.EFFECTIVE_DATE, gll.JE_LINE_NUM) as Accounting_Fark, 

gll.CURRENCY_CODE "Currency"

From  GL_JE_BATCHES glb
Inner Join GL_JE_HEADERS glh 
    Inner Join GL_JE_LINES gll
        Inner Join GL_LEDGERS gled
        ON gll.Ledger_Id = gled.Ledger_Id 
        Inner Join  GL_CODE_COMBINATIONS gcc
            Inner Join FND_VS_VALUES_B valAccoutordist
					Inner Join FND_VS_VALUES_TL valAccoutNordist
					ON valAccoutordist.Value_Id = valAccoutNordist.Value_Id 
					and valAccoutNordist.LANGUAGE = FND_GLOBAL.Current_Language
			ON valAccoutordist.Value = gcc.Segment2 and valAccoutordist.ATTRIBUTE_CATEGORY = 'ACM_Account'
        ON gll.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID
        Inner Join GL_Import_References import
            Inner Join XLA_AE_LINES xlin
                Left Join POZ_SUPPLIERs_V poz
                ON poz.Vendor_ID = xlin.Party_ID
                Left Join POZ_SUPPLIER_SITES_V supsite
                On xlin.Party_Site_ID = supsite.VENDOR_SITE_ID
            ON xlin.gl_sl_link_table = import.gl_sl_link_table and  xlin.gl_sl_link_id = import.gl_sl_link_id
        ON gll.JE_HEADER_ID  = import.JE_HEADER_ID and gll.JE_LINE_NUM = import.JE_LINE_NUM
    On glh.JE_HEADER_ID = gll.JE_HEADER_ID
ON glb.JE_BATCH_ID = glh.JE_BATCH_ID

Where  
gled.Name IN (:LEDGER)
-- gled.Name IN 'DO01_Ledger'
AND gll.PERIOD_NAME IN (:PERIOD)
-- AND gll.PERIOD_NAME = '2019-01'
-- AND glb.STATUS IN (:STATUS)
AND gcc.Segment2 IN (:ACCOUNT)
-- AND glh.JE_SOURCE IN (:SOURCE)
-- AND glh.JE_CATEGORY IN (:CATEGORY)
Order BY gll.EFFECTIVE_DATE, gll.JE_LINE_NUM