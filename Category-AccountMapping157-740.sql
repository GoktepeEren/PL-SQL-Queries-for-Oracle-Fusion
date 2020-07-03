Select
Distinct
xlep.LEGAL_ENTITY_IDENTIFIER as Identifier,
xlep.NAME as Company,
tbl_cat.START_DATE_ACTIVE,
tbl_cat.END_DATE_ACTIVE,
tbl_cat.CATEGORY_ID ,
tbl_cat.CATEGORY_NAME,


(Select 
tbl_codeXe.SEGMENT2 as Account
FROM XLA_MAPPING_SET_VALUES tbl_mapX
		Inner Join GL_CODE_COMBINATIONS tbl_codeXe
		ON tbl_codeXe.CODE_COMBINATION_ID = tbl_mapX.VALUE_CODE_COMBINATION_ID 
        and tbl_codeXe.Segment2 like '1%' 
        and tbl_codeXe.Segment1 = xlep.LEGAL_ENTITY_IDENTIFIER
Where tbl_mapX.INPUT_VALUE_CONSTANT1 = tbl_map.INPUT_VALUE_CONSTANT2 and Rownum = 1) as Inv,

(Select 
valAccoutN.Description
FROM XLA_MAPPING_SET_VALUES tbl_mapX
		Inner Join GL_CODE_COMBINATIONS tbl_codeXe
			Inner Join FND_VS_VALUES_B valAccout
				Inner Join FND_VS_VALUES_TL valAccoutN 
				ON valAccout.Value_Id = valAccoutN.Value_Id 
				and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language
				and valAccoutN.Source_Lang = FND_GLOBAL.Current_Language
			ON valAccout.Value = tbl_codeXe.Segment2 and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
		ON tbl_codeXe.CODE_COMBINATION_ID = tbl_mapX.VALUE_CODE_COMBINATION_ID 
        and tbl_codeXe.Segment2 like '1%' 
        and tbl_codeXe.Segment1 = xlep.LEGAL_ENTITY_IDENTIFIER
Where tbl_mapX.INPUT_VALUE_CONSTANT1 = tbl_map.INPUT_VALUE_CONSTANT2 and Rownum = 1) as InvName,

tbl_map.INPUT_VALUE_CONSTANT1 as RequestType,
tbl_codeX.SEGMENT2 as EXP1,
valAccoutN.Description as EXPNAME

From EGP_CATEGORIES_VL tbl_cat 
Left Join XLA_MAPPING_SET_VALUES tbl_map
	Inner Join XLA_MAPPING_SETS_B tbl_mapb 
	ON  tbl_mapb.MAPPING_SET_CODE = tbl_map.MAPPING_SET_CODE  
	And tbl_mapb.Application_Id =  '201' 
	and tbl_mapb.Owner_Code = 'C' 
	and tbl_mapb.ENABLED_FLAG = 'Y'
    Inner Join GL_CODE_COMBINATIONS tbl_codeX
		Inner Join FND_VS_VALUES_B valAccout
			Inner Join FND_VS_VALUES_TL valAccoutN 
			ON valAccout.Value_Id = valAccoutN.Value_Id 
			and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language
			and valAccoutN.Source_Lang = FND_GLOBAL.Current_Language
		ON valAccout.Value = tbl_codeX.Segment2 and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
        Inner Join  XLE_ENTITY_PROFILES xlep
		ON tbl_codeX.SEGMENT1 = xlep.LEGAL_ENTITY_IDENTIFIER
	ON tbl_codeX.CODE_COMBINATION_ID = tbl_map.VALUE_CODE_COMBINATION_ID 
On to_char(tbl_cat.CATEGORY_ID) = tbl_map.INPUT_VALUE_CONSTANT2 and tbl_mapb.ENABLED_FLAG <> 'N' 
Where tbl_cat.END_DATE_ACTIVE IS NULL  
and xlep.NAME IN (:CompanyName)