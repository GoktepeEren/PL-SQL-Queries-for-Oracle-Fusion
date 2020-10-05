-- Get Item Category Mapping to Category Hierarchy Route 
Select 
Distinct
-- item.INVENTORY_ITEM_ID,
itemas.CATEGORY_SET_ID,
itemas.CATEGORY_ID,
CatMap.Route,
CatMap.Levelx
From
egp_system_items_b item
Inner Join egp_item_cat_assignments itemas 
On item.INVENTORY_ITEM_ID = itemas.INVENTORY_ITEM_ID
and itemas.CATEGORY_SET_ID = '300000013087480' 
-- Sample Data of Oreo
-- and item.INVENTORY_ITEM_ID = '300000017355668'
	Inner Join
		(
		Select
		-- valid.CATEGORY_SET_ID,
		valid.CATEGORY_ID,
		-- cate.Category_Name as Category,
		-- valid.PARENT_CATEGORY_ID,
		-- cateman.Category_Name as Parent,
		Level as Levelx,
		replace(initcap(SYS_CONNECT_BY_PATH(cate.Category_Name, ' > ')), '')  as Route
		From
		EGP_CATEGORY_SET_VALID_CATS valid
		Inner Join EGP_Categories_TL cate ON valid.CATEGORY_ID = cate.Category_Id and cate.LANGUAGE= FND_GLOBAL.Current_Language
		Left Join EGP_Categories_TL cateman ON valid.PARENT_CATEGORY_ID = cateman.Category_Id and cateman.LANGUAGE= FND_GLOBAL.Current_Language
		-- This line is Item Category Id
		-- Where valid.CATEGORY_SET_ID = '300000013087480'
		-- START WITH valid.CATEGORY_ID = '100000019415146'
		-- Sample Category Id
		-- Where valid.CATEGORY_ID = '100000019415703' 
        Where Level = 
            (Select 
            Count(*) From
            (Select
            catex.Category_Name as Category,
		    validx.PARENT_CATEGORY_ID,
		    catemanx.Category_Name as Parent,
            Level,
		    replace(initcap(SYS_CONNECT_BY_PATH(catex.Category_Name, ' > ')), '')  as Route
            From
		    EGP_CATEGORY_SET_VALID_CATS validx
		    Inner Join EGP_Categories_TL catex ON validx.CATEGORY_ID = catex.Category_Id and catex.LANGUAGE= FND_GLOBAL.Current_Language
		    Left Join EGP_Categories_TL catemanx ON validx.PARENT_CATEGORY_ID = catemanx.Category_Id and catemanx.LANGUAGE= FND_GLOBAL.Current_Language
            Where validx.CATEGORY_ID = valid.CATEGORY_ID 
            CONNECT BY PRIOR validx.CATEGORY_ID = validx.PARENT_CATEGORY_ID
            Order By Level Desc
            ))

		CONNECT BY PRIOR valid.CATEGORY_ID = valid.PARENT_CATEGORY_ID
        
		Order By Level Desc
		) CatMap ON Catmap.Category_Id = itemas.CATEGORY_ID