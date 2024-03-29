select
DISTINCT 

BOOK_TYPE_CODE, 
ASSET_ID, ASSET_NUMBER,
PARENT_ASSET_NUMBER,
DESCRIPTION, 
DATE_PLACED_IN_SERVICE,
DEPRN_START_DATE,
ORIGINAL_COST, 
ADJUSTED_COST, 
COST,
CAPITALIZE_FLAG, 
YTD_DEPRN,
FISCAL_YEAR, 
PERIOD_NUM,
PO_NUMBER,
INVOICE_NUMBER,
INVOICE_DATE,
PAYABLES_CODE_COMBINATION_ID,
SALVAGE_VALUE,	
ATTRIBUTE_CATEGORY_CODE,
MAINCATCODE,
SUBCATCODE,

VENDOR_NUMBER,
VENDOR_NAME,
CONVENTION_TYPE_ID,
METHOD_ID,

--CLEARING_ACCT_SEGMENT1,
--CLEARING_ACCT_SEGMENT2,
--CLEARING_ACCT_SEGMENT3,
--CLEARING_ACCT_SEGMENT4,
--CLEARING_ACCT_SEGMENT5,

UNITS_ASSIGNED,

--ASSET_KEY_SEGMENT1,
LIFE_IN_MONTHS,

DEPRN_RESERVE,
MANUFACTURER_NAME,
BASIC_RATE,
ADJUSTED_RATE,



MAINCATNAME,
SUBCATNAME,

ASSET_CATEGORY_ID,

ASSET_CLEARING_ACCOUNT,

DEPRN_EXPENSE_ACCOUNT,

DATE_EFFECTIVE,
PRORATE_DATE,
DATE_INEFFECTIVE,
RECOVERABLE_COST,
UNREVALUED_COST,
ADJUSTED_RECOVERABLE_COST,
CREATION_DATE,
CREATED_BY,
LAST_UPDATE_DATE,
LAST_UPDATED_BY,
SERI_NUM

from 
(
SELECT 
A.BOOK_TYPE_CODE, 
A.ASSET_ID, B.ASSET_NUMBER,
(Select parentAsset.ASSET_NUMBER From FA_ADDITIONS_B parentAsset Where B.Parent_Asset_Id = parentAsset.Asset_Id) PARENT_ASSET_NUMBER,
C.DESCRIPTION, 
A.DATE_PLACED_IN_SERVICE,
A.DEPRN_START_DATE,
A.ORIGINAL_COST, 
A.ADJUSTED_COST, 
A.COST,
A.CAPITALIZE_FLAG, 

(select MAX(Z.YTD_DEPRN) from FA_DEPRN_SUMMARY Z
where  Z.ASSET_ID =A.ASSET_ID
AND Z.PERIOD_COUNTER=(SELECT MAX(PERIOD_COUNTER) FROM FA_DEPRN_PERIODS where PERIOD_COUNTER=Z.PERIOD_COUNTER )
AND Z.DEPRN_RESERVE <> 0 
AND Z.DEPRN_SOURCE_CODE='DEPRN'
) AS YTD_DEPRN,

(select DISTINCT E.FISCAL_YEAR from FA_DEPRN_PERIODS E,
FA_DEPRN_SUMMARY Y
where A.ASSET_ID= Y.ASSET_ID
AND E.BOOK_TYPE_CODE=Y.BOOK_TYPE_CODE
AND E.PERIOD_CLOSE_DATE is null
) AS FISCAL_YEAR,

(select DISTINCT E.PERIOD_NUM from FA_DEPRN_PERIODS E,
FA_DEPRN_SUMMARY Y
where A.ASSET_ID= Y.ASSET_ID
AND E.BOOK_TYPE_CODE=Y.BOOK_TYPE_CODE
AND E.PERIOD_CLOSE_DATE is null
) AS PERIOD_NUM,

F.PO_NUMBER,
F.INVOICE_NUMBER,
F.INVOICE_DATE,

F.PAYABLES_CODE_COMBINATION_ID,
A.SALVAGE_VALUE,	
B.ATTRIBUTE_CATEGORY_CODE,
SUBSTR(TRIM(B.ATTRIBUTE_CATEGORY_CODE), 0, 2) AS MAINCATCODE,
SUBSTR(TRIM(B.ATTRIBUTE_CATEGORY_CODE), 4, 2) AS SUBCATCODE,
F.VENDOR_NUMBER,
F.VENDOR_NAME,

( select 
 CT.DESCRIPTION
FROM FA_CONVENTION_TYPES CT
where
A.CONVENTION_TYPE_ID=CT.CONVENTION_TYPE_ID
)
AS CONVENTION_TYPE_ID,


( select 
 MC.METHOD_CODE
FROM FA_METHODS MC
where
A.METHOD_ID=MC.METHOD_ID
)
AS METHOD_ID,

--G.CLEARING_ACCT_SEGMENT1,
--G.CLEARING_ACCT_SEGMENT2,
--G.CLEARING_ACCT_SEGMENT3,
--G.CLEARING_ACCT_SEGMENT4,
--G.CLEARING_ACCT_SEGMENT5,

(Select J.UNITS_ASSIGNED from FA_DISTRIBUTION_HISTORY J
where A.ASSET_ID=J.ASSET_ID AND J.DATE_INEFFECTIVE is null) AS UNITS_ASSIGNED,


--G.ASSET_KEY_SEGMENT1,




( select 
FM.LIFE_IN_MONTHS
FROM FA_METHODS FM
where
FM.METHOD_ID=A.METHOD_ID
)
AS LIFE_IN_MONTHS,


(select MAX(Z.DEPRN_RESERVE) from FA_DEPRN_SUMMARY Z
where  Z.ASSET_ID =A.ASSET_ID
AND Z.PERIOD_COUNTER=(SELECT MAX(PERIOD_COUNTER) FROM FA_DEPRN_PERIODS where PERIOD_COUNTER=Z.PERIOD_COUNTER )
AND Z.DEPRN_RESERVE <> 0 
AND Z.DEPRN_SOURCE_CODE='DEPRN'

) AS DEPRN_RESERVE,


B.MANUFACTURER_NAME,



( select 
FFR.BASIC_RATE
FROM FA_FLAT_RATES FFR
where
FFR.METHOD_ID=A.METHOD_ID
)
AS BASIC_RATE,

( select 
FFR.ADJUSTED_RATE
FROM FA_FLAT_RATES FFR
where
FFR.METHOD_ID=A.METHOD_ID
)
AS ADJUSTED_RATE,



(Select 
DISTINCT TL.Description
From FND_VS_VALUES_B B,
FND_VS_VALUES_TL TL
WHERE B.VALUE_ID = TL.VALUE_ID 
and B.Value = SUBSTR(TRIM(B.ATTRIBUTE_CATEGORY_CODE), 0, 2)
and B.ATTRIBUTE_CATEGORY like 'Major_Category_VS'
and TL.LANGUAGE = fnd_Global.Current_Language) MAINCATNAME,

(Select 
DISTINCT TL.Description
From FND_VS_VALUES_B B,
FND_VS_VALUES_TL TL
WHERE B.VALUE_ID = TL.VALUE_ID 
and B.Value = SUBSTR(TRIM(B.ATTRIBUTE_CATEGORY_CODE), 4, 2)
and B.ATTRIBUTE_CATEGORY like 'Minor_Category_VS'
and B.INDEPENDENT_VALUE= SUBSTR(TRIM(B.ATTRIBUTE_CATEGORY_CODE), 0, 2)
and TL.LANGUAGE = fnd_Global.Current_Language) SUBCATNAME,

B.ASSET_CATEGORY_ID,



( select 
 ( select 
 GL.SEGMENT2
FROM GL_CODE_COMBINATIONS GL
where
FCB.ASSET_CLEARING_ACCOUNT_CCID=GL.CODE_COMBINATION_ID

)
FROM FA_CATEGORY_BOOKS FCB
where FCB.CATEGORY_ID=B.ASSET_CATEGORY_ID
AND FCB.BOOK_TYPE_CODE=A.BOOK_TYPE_CODE

) as ASSET_CLEARING_ACCOUNT,



( select 
( select 
GL.SEGMENT2
FROM GL_CODE_COMBINATIONS GL
where
FCB.DEPRN_EXPENSE_ACCOUNT_CCID=GL.CODE_COMBINATION_ID

)
FROM FA_CATEGORY_BOOKS FCB
where FCB.CATEGORY_ID=B.ASSET_CATEGORY_ID
AND FCB.BOOK_TYPE_CODE=A.BOOK_TYPE_CODE

) as DEPRN_EXPENSE_ACCOUNT,




A.DATE_EFFECTIVE,
A.PRORATE_DATE,
A.DATE_INEFFECTIVE,
A.RECOVERABLE_COST,
A.UNREVALUED_COST,
A.ADJUSTED_RECOVERABLE_COST,
A.CREATION_DATE,
A.CREATED_BY,
A.LAST_UPDATE_DATE,
A.LAST_UPDATED_BY,
B.SERIAL_NUMBER AS SERI_NUM

FROM FA_BOOKS A, FA_ADDITIONS_B B, FA_ADDITIONS_TL C ,
--FA_DEPRN_SUMMARY D, 
--FA_DEPRN_PERIODS E,
FA_ASSET_INVOICES F
--FA_MASS_ADDITIONS G,
--FA_DISTRIBUTION_HISTORY J

 
WHERE A.ASSET_ID=B.ASSET_ID(+)
AND A.ASSET_ID=C.ASSET_ID(+)
--AND A.ASSET_ID= D.ASSET_ID(+)
--AND D.PERIOD_COUNTER= (SELECT MAX(PERIOD_COUNTER) FROM FA_DEPRN_PERIODS where PERIOD_COUNTER=D.PERIOD_COUNTER and PERIOD_COUNTER=E.PERIOD_COUNTER )
--AND D.DEPRN_RESERVE <> 0 
AND A.ASSET_ID=F.ASSET_ID(+)
--AND A.ASSET_ID=G.ASSET_ID
--AND A.ASSET_ID=J.ASSET_ID(+)

--AND D.DEPRN_SOURCE_CODE='DEPRN'


AND A.BOOK_TYPE_CODE IN (:P_BOOKTYPE)

AND A.DATE_INEFFECTIVE IS NULL

--AND F.SPLIT_MERGED_CODE='MP'
--Not Retired
--AND A.DEPRECIATE_FLAG ='YES'
-- Retired
AND A.DEPRECIATE_FLAG ='NO'


) t1

ORDER BY ASSET_NUMBER,BOOK_TYPE_CODE,FISCAL_YEAR