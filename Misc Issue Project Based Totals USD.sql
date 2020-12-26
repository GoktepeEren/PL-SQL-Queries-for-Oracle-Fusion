Select 

TransDetailTable.ITEM_NUMBER,
TransDetailTable.Item_Desc,
TransDetailTable.Project,
TransDetailTable.QuantityItem,
TransDetailTable.SubInventory,
TransDetailTable.TranUom,
TransDetailTable.TranDate,
TransDetailTable.TranRef,
TransDetailTable.CostCat,
TransDetailTable.LocationTo,
TransDetailTable.OrderNumber,
TransDetailTable.ItemUnitWoutTx,
TransDetailTable.ItemUnitWTx,

(TransDetailTable.QuantityItem * TransDetailTable.ItemUnitWoutTx) as TotalWoutTx,
(TransDetailTable.QuantityItem * TransDetailTable.ItemUnitWTx) as TotalWoTx


From 

(Select


invtra.Transaction_Id,
invtype.Transaction_Type_Name,
Case 
When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Common Expenses'
When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Common Expenses'
When proc.SEGMENT1 is not null Then proc.SEGMENT1
Else 'Non-Project'
End as Project,
invtra.Inventory_Item_Id,
item.ITEM_NUMBER,
item.DESCRIPTION Item_Desc,
invtra.TRANSACTION_QUANTITY QuantityItem,
invtra.SUBINVENTORY_CODE SubInventory,
invtra.TRANSACTION_UOM TranUom,
invtra.TRANSACTION_DATE TranDate,
invtra.TRANSACTION_REFERENCE TranRef,
NVL(costcat.Description, 'Non-CostCat') CostCat,
NVL(placeexp.Description, 'Non-Location') LocationTo,

(Select * From 
        (Select poh.SEGMENT1
        From PO_LINES_ALL pol
        Inner Join PO_HEADERS_ALL poh 
            Left Join gl_daily_rates dorderrate            
            ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
            And dorderrate.Conversion_Type = 'Corporate' 
            and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
        ON poh.PO_HEADER_ID = pol.PO_HEADER_ID and poh.Document_Status IN ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
        Inner Join PO_Distributions_ALL pod ON pol.PO_LINE_ID = pod.PO_LINE_ID
        Where invtra.Inventory_Item_Id = pol.Item_ID      
        and invtra.TRANSACTION_UOM = pol.UOM_CODE     
        and invtra.TRANSACTION_DATE > poh.CREATION_DATE
        and invorg.BUSINESS_UNIT_ID = pol.PRC_BU_ID
        Order By poh.CREATION_DATE DESC)
    Where Rownum <= 1) OrderNumber,


(Select * From 
        (Select
            Trunc(((Case 
            WHEN poh.CURRENCY_CODE = 'USD' Then Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2)
            Else Trunc(Trunc((pod.TAX_EXCLUSIVE_AMOUNT),2) / 
                Case
                When dorderrate.Conversion_Rate is not null then TRUNC(dorderrate.Conversion_Rate,2)
                Else (Select * From
                            (Select dorderratex.Conversion_Rate From gl_daily_rates dorderratex 
                            Where dorderratex.From_Currency = 'USD' and dorderratex.TO_Currency = poh.CURRENCY_CODE
                            And dorderratex.Conversion_Type = 'Corporate' and Trunc(dorderratex.CONVERSION_DATE) < Trunc(poh.Creation_date)
                            Order By dorderratex.Conversion_Rate) Where Rownum <= 1)
                End, 2)
            End) / pod.QUANTITY_ORDERED), 2) ItemUnitWoutTx
        From PO_LINES_ALL pol
        Inner Join PO_HEADERS_ALL poh 
            Left Join gl_daily_rates dorderrate            
            ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
            And dorderrate.Conversion_Type = 'Corporate' 
            and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
        ON poh.PO_HEADER_ID = pol.PO_HEADER_ID and poh.Document_Status IN ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
        Inner Join PO_Distributions_ALL pod ON pol.PO_LINE_ID = pod.PO_LINE_ID
        Where invtra.Inventory_Item_Id = pol.Item_ID      
        and invtra.TRANSACTION_UOM = pol.UOM_CODE     
        and invtra.TRANSACTION_DATE > poh.CREATION_DATE
        and invorg.BUSINESS_UNIT_ID = pol.PRC_BU_ID
        Order By poh.CREATION_DATE DESC)
    Where Rownum <= 1) ItemUnitWoutTx,

(Select * From 
        (Select
            Trunc(((Case 
            WHEN poh.CURRENCY_CODE = 'USD' Then Trunc((RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2)
            Else Trunc(Trunc((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT),2) / 
                Case
                When dorderrate.Conversion_Rate is not null then TRUNC(dorderrate.Conversion_Rate,2)
                Else (Select * From
                        (Select dorderratex.Conversion_Rate From gl_daily_rates dorderratex 
                        Where dorderratex.From_Currency = 'USD' and dorderratex.TO_Currency = poh.CURRENCY_CODE
                        And dorderratex.Conversion_Type = 'Corporate' and Trunc(dorderratex.CONVERSION_DATE) < Trunc(poh.Creation_date)
                        Order By dorderratex.Conversion_Rate) Where Rownum <= 1)
                End, 2)
            End) / pod.QUANTITY_ORDERED), 2) ItemUnitWTx
        From PO_LINES_ALL pol
        Inner Join PO_HEADERS_ALL poh 
            Left Join gl_daily_rates dorderrate            
            ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
            And dorderrate.Conversion_Type = 'Corporate' 
            and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
        ON poh.PO_HEADER_ID = pol.PO_HEADER_ID and poh.Document_Status IN ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
        Inner Join PO_Distributions_ALL pod ON pol.PO_LINE_ID = pod.PO_LINE_ID
        Where invtra.Inventory_Item_Id = pol.Item_ID      
        and invtra.TRANSACTION_UOM = pol.UOM_CODE     
        and invtra.TRANSACTION_DATE > poh.CREATION_DATE
        and invorg.BUSINESS_UNIT_ID = pol.PRC_BU_ID
        Order By poh.CREATION_DATE DESC)
    Where Rownum <= 1) ItemUnitWTx

From INV_MATERIAL_TXNS invtra
Inner Join INV_TRANSACTION_TYPES_VL invtype ON invtra.Transaction_Type_Id = invtype.TRANSACTION_TYPE_ID and invtype.Transaction_Type_Name = 'Miscellaneous Project Issue' 
Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = invtra.PJC_PROJECT_ID
Inner Join INV_ORG_PARAMETERS invorg ON invorg.Organization_Id = invtra.Organization_Id
Inner Join egp_system_items_vl item ON item.Inventory_Item_Id = invtra.Inventory_Item_Id and item.Organization_Id = invtra.Organization_Id
Left Join FND_VS_VALUES_VL costcat ON costcat.Value = invtra.ATTRIBUTE1 and costcat.ATTRIBUTE_CATEGORY like 'ACM_Business_Function_VS' 
Left Join FND_VS_VALUES_VL placeexp ON placeexp.Value = invtra.ATTRIBUTE8 and placeexp.ATTRIBUTE_CATEGORY like 'ACM_Place_VS' 
-- and invtra.Inventory_Item_ID = '300000014045747'
Where 
Trunc(invtra.TRANSACTION_DATE) between NVL(:StartDate, To_Date('22.09.1992','dd.MM.yyyy')) and NVL(:EndDate, To_Date('31.12.2100','dd.MM.yyyy'))

Order By invtra.CREATION_DATE DESC) TransDetailTable

Where (TransDetailTable.Project IN (:Project) OR 'All' IN (:Project || 'All'))
and (TransDetailTable.LocationTo IN (:LocationTo) OR 'All' IN (:LocationTo || 'All'))
-- Group By TransDetailTable.Project

-- Order By TransDetailTable.Project