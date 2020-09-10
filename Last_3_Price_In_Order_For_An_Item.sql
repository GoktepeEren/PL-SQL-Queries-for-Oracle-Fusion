Select
Distinct
horg.Name as BusinessUnit,
item.Organization_Code,
item.ITEM_NUMBER,
cati.Category_Name as PurchasingCategory,
item.DESCRIPTION,
poh.Segment1 as OrderNumber,
pol.Line_Status,
pol.UNIT_PRICE as OrderUnitPrice,
Item.LIST_PRICE_PER_UNIT as SystemUnitPrice,
poh.currency_code,
poh.Creation_Date,
(Select
pohx.Currency_Code
From PO_HEADERS_ALL pohx 
Where horg.Organization_Id = pohx.BILLTO_BU_ID
and  pohx.Rate is null and rownum <= 1
) as DefaultCurrency

From
egp_system_items_vl item
-- For Purchasing Category
Left Join EGP_ITEM_CAT_ASSIGNMENTS icat 
    Inner Join EGP_CATEGORIES_VL cati ON icat.Category_Id = cati.Category_Id and (cati.END_DATE_ACTIVE is null OR cati.END_DATE_ACTIVE > sysdate) 
ON item.Inventory_Item_Id = icat.Inventory_Item_Id and icat.CATEGORY_SET_ID  = '300000009379384'

Inner Join PO_LINES_ALL pol 
  Inner Join PO_HEADERS_ALL poh 
    Inner Join hr_organization_units horgy
    ON horgy.Organization_Id = poh.BILLTO_BU_ID 
  ON pol.PO_HEADER_ID = poh.PO_HEADER_ID
ON pol.ITEM_ID = item.Inventory_ITEM_ID 

Inner Join INV_ORG_PARAMETERS invorg
  Inner Join hr_organization_units horg
  ON horg.Organization_Id = invorg.BUSINESS_UNIT_ID
ON invorg.ORGANIZATION_ID = item.Organization_Id



Where item.INVENTORY_ITEM_STATUS_CODE <> 'Inactive' 
and horg.Name IN (:OrganizationCode) and horgy.Name IN (:OrganizationCode)  and poh.Segment1 not like '%PA%'  
-- and item.ITEM_NUMBER = '214805'
and pol.po_line_id IN (
    Select
    *
    From
      (
        Select
        PO_LINE_ID
        From
        PO_LINES_ALL polx
            Inner Join PO_HEADERS_ALL pohx
                Inner Join hr_organization_units horgx
                ON horgx.Organization_Id = pohx.BILLTO_BU_ID 
            ON polx.PO_HEADER_ID = pohx.PO_HEADER_ID
        Where polx.ITEM_ID = item.Inventory_ITEM_ID
        and polx.Line_Status IN ('OPEN','CLOSED FOR RECEIVING','CLOSED FOR INVOICING','CLOSED')
        and horgx.Name IN (:OrganizationCode)
        Order By polx.Creation_Date DESC
      )  Where rownum <= 4  
  )
Order By poh.Creation_Date DESC