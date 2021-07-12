Select
Distinct
horg.Name,
item.Organization_Code,
item.ITEM_NUMBER,
item.INVENTORY_ITEM_STATUS_CODE,
item.PRIMARY_UOM_CODE,
item.DESCRIPTION,
item.LONG_DESCRIPTION,
cati.Category_Name as PurchasingCategory,
catitem.Category_Name as ItemCategory,
tbl_map.INPUT_VALUE_CONSTANT1 as RequestType,
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
tbl_codeX.SEGMENT2 as EXP1,
valAccout.Description as EXPNAME,

item.STOCK_ENABLED_FLAG,
item.LIST_PRICE_PER_UNIT
From
egp_system_items_vl item
-- For Purchasing Category
Left Join EGP_ITEM_CAT_ASSIGNMENTS icat 
    Inner Join EGP_CATEGORIES_VL cati 
        Left Join XLA_MAPPING_SET_VALUES tbl_map
            Inner Join XLA_MAPPING_SETS_B tbl_mapb 
            ON  tbl_mapb.MAPPING_SET_CODE = tbl_map.MAPPING_SET_CODE  
            And tbl_mapb.Application_Id =  '201' 
            and tbl_mapb.Owner_Code = 'C' 
            and tbl_mapb.ENABLED_FLAG = 'Y'
            Inner Join GL_CODE_COMBINATIONS tbl_codeX
                Inner Join FND_VS_VALUES_VL valAccout
                ON valAccout.Value = tbl_codeX.Segment2 and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
                Inner Join  XLE_ENTITY_PROFILES xlep
                ON tbl_codeX.SEGMENT1 = xlep.LEGAL_ENTITY_IDENTIFIER
            ON tbl_codeX.CODE_COMBINATION_ID = tbl_map.VALUE_CODE_COMBINATION_ID 
        On to_char(cati.Category_Id) = tbl_map.INPUT_VALUE_CONSTANT2 
    ON icat.Category_Id = cati.Category_Id and (cati.END_DATE_ACTIVE is null OR cati.END_DATE_ACTIVE > sysdate) 
    
ON item.Inventory_Item_Id = icat.Inventory_Item_Id and icat.CATEGORY_SET_ID  = '300000009379384'
-- For Item Category
Left Join EGP_ITEM_CAT_ASSIGNMENTS icatitemcat
    Inner Join EGP_CATEGORIES_VL catitem ON icatitemcat.Category_Id = catitem.Category_Id and (catitem.END_DATE_ACTIVE is null OR catitem.END_DATE_ACTIVE > sysdate)   
ON item.Inventory_Item_Id = icatitemcat.Inventory_Item_Id and icatitemcat.CATEGORY_SET_ID  = '300000013087480'
Inner Join hr_organization_units horg
ON horg.Organization_Id = item.Organization_Id

Where 
-- item.INVENTORY_ITEM_STATUS_CODE <> 'Inactive' and 
item.INVENTORY_ITEM_STATUS_CODE IN (:ItemStatus) and
Substr(horg.Name,1,4) = tbl_codeX.Segment1 and
-- item.Organization_Code IN (:OrgName)
horg.Name IN (:OrgName)
Order By item.ITEM_NUMBER DESC