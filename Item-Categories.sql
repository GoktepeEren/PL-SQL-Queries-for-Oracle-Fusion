
Select
item.Organization_Code,
item.ITEM_NUMBER,
item.DESCRIPTION,
item.LONG_DESCRIPTION,
cati.Category_Name as PurchasingCategory,
catitem.Category_Name as ItemCategory
From
egp_system_items_vl item
-- For Purchasing Category
Left Join EGP_ITEM_CAT_ASSIGNMENTS icat 
    Inner Join EGP_CATEGORIES_VL cati ON icat.Category_Id = cati.Category_Id and (cati.END_DATE_ACTIVE is null OR cati.END_DATE_ACTIVE > sysdate) 
ON item.Inventory_Item_Id = icat.Inventory_Item_Id and icat.CATEGORY_SET_ID  = '300000009379384'
-- For Item Category
Left Join EGP_ITEM_CAT_ASSIGNMENTS icatitemcat
    Inner Join EGP_CATEGORIES_VL catitem ON icatitemcat.Category_Id = catitem.Category_Id and (catitem.END_DATE_ACTIVE is null OR catitem.END_DATE_ACTIVE > sysdate)   
ON item.Inventory_Item_Id = icatitemcat.Inventory_Item_Id and icatitemcat.CATEGORY_SET_ID  = '300000013087480'
Where item.INVENTORY_ITEM_STATUS_CODE <> 'Inactive' 
and item.Organization_Code =  (:OrgName)
Order By item.DESCRIPTION
