Select 

TransDetailTable.ITEM_NUMBER,
TransDetailTable.Item_Desc,
TransDetailTable.Project,
TransDetailTable.QuantityItem,
TransDetailTable.SubInventory,
TransDetailTable.ExpItemDate,
TransDetailTable.TranUom,
TransDetailTable.TranDate,
TransDetailTable.TranRef,
TransDetailTable.CostCat,
TransDetailTable.LocationTo,
TransDetailTable.OrderNumber,
TransDetailTable.ItemUnitWoutTx,
TransDetailTable.ItemUnitWTx,
TransDetailTable.ItemUnitWoutTxDop,
TransDetailTable.ItemUnitWTxDop,
TransDetailTable.ExpOrg


From 

(Select


invtra.Transaction_Id,
invtype.Transaction_Type_Name,
Case 
When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
When proc.SEGMENT1 is not null Then proc.SEGMENT1
Else Null
End as Project,
invtra.Inventory_Item_Id,
item.ITEM_NUMBER,
item.DESCRIPTION Item_Desc,
invtra.TRANSACTION_QUANTITY QuantityItem,
invtra.SUBINVENTORY_CODE SubInventory,
invtra.TRANSACTION_UOM TranUom,
invtra.TRANSACTION_DATE TranDate,
invtra.TRANSACTION_REFERENCE TranRef,
costcat.Description CostCat,
placeexp.Description LocationTo,
invtra.PJC_Expenditure_Item_Date ExpItemDate,
horgline.Name ExpOrg,

(Select * From 
        (Select poh.SEGMENT1
        From PO_LINES_ALL pol
        Inner Join PO_HEADERS_ALL poh 
            Left Join gl_daily_rates dorderrate            
            ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
            And dorderrate.Conversion_Type = 'Corporate' 
            and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
        ON poh.PO_HEADER_ID = pol.PO_HEADER_ID -- and poh.Document_Status IN ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
        Inner Join PO_Distributions_ALL pod ON pol.PO_LINE_ID = pod.PO_LINE_ID
        Where invtra.Inventory_Item_Id = pol.Item_ID      
        and invtra.TRANSACTION_UOM = pol.UOM_CODE     
        and invtra.TRANSACTION_DATE > poh.CREATION_DATE
        and invorg.BUSINESS_UNIT_ID = pol.PRC_BU_ID
        and pol.Line_Status IN ('CLOSED','CLOSED FOR INVOICING', 'CLOSED FOR RECEIVING','FINALLY CLOSED')
        Order By poh.CREATION_DATE DESC)
    Where Rownum <= 1) OrderNumber,


(Select * From 
        (Select
            Trunc(((Case 
            WHEN poh.CURRENCY_CODE = 'USD' Then (pod.TAX_EXCLUSIVE_AMOUNT)
            Else (pod.TAX_EXCLUSIVE_AMOUNT) / 
                Case
                When dorderrate.Conversion_Rate is not null then TRUNC(dorderrate.Conversion_Rate,2)
                Else (Select * From
                            (Select Trunc(dorderratex.Conversion_Rate, 2) From gl_daily_rates dorderratex 
                            Where dorderratex.From_Currency = 'USD' and dorderratex.TO_Currency = poh.CURRENCY_CODE
                            And dorderratex.Conversion_Type = 'Corporate' and Trunc(dorderratex.CONVERSION_DATE) < Trunc(poh.Creation_date)
                            Order By dorderratex.Conversion_Rate) Where Rownum <= 1)
                End
            End) / pod.QUANTITY_ORDERED), 5) ItemUnitWoutTx
        From PO_LINES_ALL pol
        Inner Join PO_HEADERS_ALL poh 
            Left Join gl_daily_rates dorderrate            
            ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
            And dorderrate.Conversion_Type = 'Corporate' 
            and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
        ON poh.PO_HEADER_ID = pol.PO_HEADER_ID -- and poh.Document_Status IN ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
        Inner Join PO_Distributions_ALL pod ON pol.PO_LINE_ID = pod.PO_LINE_ID
        Where invtra.Inventory_Item_Id = pol.Item_ID      
        and invtra.TRANSACTION_UOM = pol.UOM_CODE     
        and invtra.TRANSACTION_DATE > poh.CREATION_DATE
        and invorg.BUSINESS_UNIT_ID = pol.PRC_BU_ID
        and pol.Line_Status IN ('CLOSED','CLOSED FOR INVOICING', 'CLOSED FOR RECEIVING','FINALLY CLOSED')
        Order By poh.CREATION_DATE DESC)
    Where Rownum <= 1) ItemUnitWoutTx,

(Select * From 
        (Select
            Trunc(((Case 
            WHEN poh.CURRENCY_CODE = 'USD' Then (RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT)
            Else (pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT) / 
                Case
                When dorderrate.Conversion_Rate is not null then TRUNC(dorderrate.Conversion_Rate,2)
                Else (Select * From
                        (Select Trunc(dorderratex.Conversion_Rate,2) From gl_daily_rates dorderratex 
                        Where dorderratex.From_Currency = 'USD' and dorderratex.TO_Currency = poh.CURRENCY_CODE
                        And dorderratex.Conversion_Type = 'Corporate' and Trunc(dorderratex.CONVERSION_DATE) < Trunc(poh.Creation_date)
                        Order By dorderratex.Conversion_Rate) Where Rownum <= 1)
                End
            End) / pod.QUANTITY_ORDERED), 5) ItemUnitWTx
        From PO_LINES_ALL pol
        Inner Join PO_HEADERS_ALL poh 
            Left Join gl_daily_rates dorderrate            
            ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
            And dorderrate.Conversion_Type = 'Corporate' 
            and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
        ON poh.PO_HEADER_ID = pol.PO_HEADER_ID  -- and poh.Document_Status IN ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
        Inner Join PO_Distributions_ALL pod ON pol.PO_LINE_ID = pod.PO_LINE_ID
        Where invtra.Inventory_Item_Id = pol.Item_ID      
        and invtra.TRANSACTION_UOM = pol.UOM_CODE     
        and invtra.TRANSACTION_DATE > poh.CREATION_DATE
        and invorg.BUSINESS_UNIT_ID = pol.PRC_BU_ID
        and pol.Line_Status IN ('CLOSED','CLOSED FOR INVOICING', 'CLOSED FOR RECEIVING','FINALLY CLOSED')
        Order By poh.CREATION_DATE DESC)
    Where Rownum <= 1) ItemUnitWTx,

    (Select * From 
        (Select
            Trunc(((Case 
            WHEN poh.CURRENCY_CODE = 'DOP' Then (RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT)
            Else (pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT) * poh.RATE
            End) / pod.QUANTITY_ORDERED), 5) ItemUnitWTx
        From PO_LINES_ALL pol
        Inner Join PO_HEADERS_ALL poh 
        ON poh.PO_HEADER_ID = pol.PO_HEADER_ID  -- and poh.Document_Status IN ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
        Inner Join PO_Distributions_ALL pod ON pol.PO_LINE_ID = pod.PO_LINE_ID
        Where invtra.Inventory_Item_Id = pol.Item_ID      
        and invtra.TRANSACTION_UOM = pol.UOM_CODE     
        and invtra.TRANSACTION_DATE > poh.CREATION_DATE
        and invorg.BUSINESS_UNIT_ID = pol.PRC_BU_ID
        and pol.Line_Status IN ('CLOSED','CLOSED FOR INVOICING', 'CLOSED FOR RECEIVING','FINALLY CLOSED')
        Order By poh.CREATION_DATE DESC)
    Where Rownum <= 1) ItemUnitWTxDop,

(Select * From 
        (Select
            Trunc(((Case 
            WHEN poh.CURRENCY_CODE = 'DOP' Then (pod.TAX_EXCLUSIVE_AMOUNT)
            Else (pod.TAX_EXCLUSIVE_AMOUNT) * poh.Rate
            End) / pod.QUANTITY_ORDERED), 5) ItemUnitWoutTx
        From PO_LINES_ALL pol
        Inner Join PO_HEADERS_ALL poh 
        ON poh.PO_HEADER_ID = pol.PO_HEADER_ID -- and poh.Document_Status IN ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
        Inner Join PO_Distributions_ALL pod ON pol.PO_LINE_ID = pod.PO_LINE_ID
        Where invtra.Inventory_Item_Id = pol.Item_ID      
        and invtra.TRANSACTION_UOM = pol.UOM_CODE     
        and invtra.TRANSACTION_DATE > poh.CREATION_DATE
        and invorg.BUSINESS_UNIT_ID = pol.PRC_BU_ID
        and pol.Line_Status IN ('CLOSED','CLOSED FOR INVOICING', 'CLOSED FOR RECEIVING','FINALLY CLOSED')
        Order By poh.CREATION_DATE DESC)
    Where Rownum <= 1) ItemUnitWoutTxDop

-- (Select * From 
--     (Select
--             poh.Currency_Code Currency
--     From PO_LINES_ALL pol
--     Inner Join PO_HEADERS_ALL poh ON poh.PO_HEADER_ID = pol.PO_HEADER_ID and poh.Document_Status IN ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
--     Inner Join PO_Distributions_ALL pod ON pol.PO_LINE_ID = pod.PO_LINE_ID
--     Where invtra.Inventory_Item_Id = pol.Item_ID      
--     and invtra.TRANSACTION_UOM = pol.UOM_CODE     
--     and invtra.TRANSACTION_DATE > poh.CREATION_DATE
--     and invorg.BUSINESS_UNIT_ID = pol.PRC_BU_ID
--     Order By poh.CREATION_DATE DESC)
-- Where Rownum <= 1) Currency
-- ordprice.ItemUnitWoutTx,
-- ordprice.ItemUnitWTx,
-- ordprice.Currency

From INV_MATERIAL_TXNS invtra
Inner Join INV_TRANSACTION_TYPES_VL invtype ON invtra.Transaction_Type_Id = invtype.TRANSACTION_TYPE_ID and invtype.Transaction_Type_Name = 'Miscellaneous Project Issue' 
Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = invtra.PJC_PROJECT_ID
Inner Join INV_ORG_PARAMETERS invorg ON invorg.Organization_Id = invtra.Organization_Id
Inner Join egp_system_items_vl item ON item.Inventory_Item_Id = invtra.Inventory_Item_Id and item.Organization_Id = invtra.Organization_Id
Left Join FND_VS_VALUES_VL costcat ON costcat.Value = invtra.ATTRIBUTE1 and costcat.ATTRIBUTE_CATEGORY like 'ACM_Business_Function_VS' 
Left Join FND_VS_VALUES_VL placeexp ON placeexp.Value = invtra.ATTRIBUTE8 and placeexp.ATTRIBUTE_CATEGORY like 'ACM_Place_VS' 
Left Join HR_ORGANIZATION_V horgline
ON invtra.PJC_ORGANIZATION_ID = horgline.ORGANIZATION_ID  and horgline.CLASSIFICATION_CODE='DEPARTMENT' and horgline.STATUS='A' and horgline.ATTRIBUTE3 like '%Direktörlük%'
and Trunc(Sysdate) between Trunc(horgline.EFFECTIVE_START_DATE) and Trunc(horgline.EFFECTIVE_END_DATE)
-- and invtra.Inventory_Item_ID = '300000014045747'
Where 1=1
-- and Trunc(invtra.TRANSACTION_DATE) between :P_Start and :P_End 
and item.ITEM_NUMBER = '222266'
Order By invtra.CREATION_DATE DESC) TransDetailTable
-- Group By TransDetailTable.Project

-- Order By TransDetailTable.Project