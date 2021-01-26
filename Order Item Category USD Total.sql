Select

ProjectGraphV3.Company,
-- ProjectGraphV3.Segment1,
ProjectGraphV3.Project,
ProjectGraphV3.Purc_Category_Name,
ProjectGraphV3.ItemCategory_Name,
ProjectGraphV3.ItemCategory_Name1,
ProjectGraphV3.ItemCategory_Name2,
ProjectGraphV3.ItemCategory_Name3,
ProjectGraphV3.Month,
Sum(ProjectGraphV3.AmountUSD) AmountUSD

From
(SELECT

org.Name as Company,

-- Poh.Segment1,

Case 
When proc.SEGMENT1 = 'DoNotUse-La Romana Common' Then 'La Romana Projects Common'
When proc.SEGMENT1 = 'La Romana Common-Old' Then 'La Romana Projects Common'
When proc.SEGMENT1 is not null Then proc.SEGMENT1
When pod.ATTRIBUTE12 = 'OPRL.CMMN.0001' Then 'La Romana Projects Common'
When pod.ATTRIBUTE12 = 'INVT.LRMN.001' Then 'La Romana Projects Common'
When pod.ATTRIBUTE12 is not null Then SubPDesc.Description
Else 'Non-Project'
End
as Project,

TO_CHAR(poh.Creation_date, 'YYYY, MONTH') as Month,

Initcap(cate.Category_Name) as Purc_Category_Name,

(Case 
When pol.ITEM_ID is null Then 'Undefinable Item Category (Non-Catalog)'
When catitem.Category_Name is null Then 'Undefined Item Category' 
Else Initcap(catitem.Category_Name)
End 
) as ItemCategory_Name,


(Case 
When pol.ITEM_ID is null Then 'Undefinable Item Category (Non-Catalog)'
When catitem.Category_Name is null Then 'Undefined Item Category' 
When cateman.Category_Name is null Then 'Undefined Item Category'
Else Initcap(cateman.Category_Name)
End 
) as ItemCategory_Name1,


(Case 
When pol.ITEM_ID is null Then 'Undefinable Item Category (Non-Catalog)'
When catitem.Category_Name is null Then 'Undefined Item Category' 
When cateman.Category_Name is null Then 'Undefined Item Category'
When cateman2.Category_Name is null Then Initcap(cateman.Category_Name) 
Else Initcap(cateman2.Category_Name)
End 
) as ItemCategory_Name2,

-- Optional can added
(Case 
When pol.ITEM_ID is null Then 'Undefinable Item Category (Non-Catalog)'
When Initcap(catitem.Category_Name) is null Then 'Undefined Item Category' 
When Initcap(cateman.Category_Name) is null Then 'Undefined Item Category'
When Initcap(cateman2.Category_Name) is null Then Initcap(cateman.Category_Name )
When Initcap(cateman3.Category_Name) is null Then Initcap(cateman2.Category_Name )
Else Initcap(cateman3.Category_Name)
End 
) as ItemCategory_Name3,

-- Sum
(Case
When org.Name like 'DO%' Then
    (Case 
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
    End)
Else
    (Case 
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
    End)
End) AmountUSD


From PO_LINES_ALL pol
Inner Join PO_HEADERS_ALL poh 
	Inner Join HR_ORGANIZATION_UNITS_F_TL  org 
	On poh.BILLTO_BU_ID = org.ORGANIZATION_ID and org.Language = 'US'
    Left Join gl_daily_rates dorderrate            
	ON dorderrate.From_Currency = 'USD' and dorderrate.TO_Currency = poh.CURRENCY_CODE
	And dorderrate.Conversion_Type = 'Corporate' 
	and dorderrate.CONVERSION_DATE = To_Date(To_Char(poh.CREATION_DATE, 'dd.MM.yyyy'),'dd.MM.yyyy')
ON pol.PO_HEADER_ID = poh.PO_HEADER_ID and poh.Document_Status in ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING', 'FINALLY CLOSED')
Inner Join PO_DISTRIBUTIONS_ALL pod 
    Left Join FND_VS_VALUES_B SubPValue
        Inner Join FND_VS_VALUES_TL SubPDesc
        ON SubPValue.VALUE_ID = SubPDesc.VALUE_ID
        and SubPDesc.LANGUAGE = fnd_Global.Current_Language
        ON pod.ATTRIBUTE12 = SubPValue.Value
        AND pod.ATTRIBUTE11 = SubPValue.INDEPENDENT_VALUE
    and SubPValue.ATTRIBUTE_CATEGORY = 'ACM_SubProject_VS'
    -- and horghead.ATTRIBUTE3 like '%Direktörlük%'
ON pol.PO_LINE_ID = pod.PO_LINE_ID 
-- Purchasing Category
Left join EGP_Categories_VL cate ON cate.Category_Id = pol.Category_Id 
-- Item Category
Left Join EGP_ITEM_CAT_ASSIGNMENTS icatitemcat
    Inner Join EGP_CATEGORIES_VL catitem 
        Left Join EGP_CATEGORY_SET_VALID_CATS valid
            Left Join EGP_CATEGORIES_VL cateman 
                Left Join EGP_CATEGORY_SET_VALID_CATS valid2
                    Left Join EGP_CATEGORIES_VL cateman2 
                        -- Optioanlly can added
                        Left Join EGP_CATEGORY_SET_VALID_CATS valid3
                            Left Join EGP_CATEGORIES_VL cateman3 
                            ON valid3.PARENT_CATEGORY_ID = cateman3.Category_Id
                        ON valid3.Category_Id = cateman2.Category_Id
                    ON valid2.PARENT_CATEGORY_ID = cateman2.Category_Id
                ON valid2.Category_Id = cateman.Category_Id
            ON valid.PARENT_CATEGORY_ID = cateman.Category_Id
        ON valid.Category_ID = catitem.Category_Id
    ON icatitemcat.Category_Id = catitem.Category_Id and (catitem.END_DATE_ACTIVE is null OR catitem.END_DATE_ACTIVE > sysdate)   
ON pol.ITEM_ID = icatitemcat.Inventory_Item_Id and icatitemcat.CATEGORY_SET_ID  = '300000013087480'

Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = pod.PJC_PROJECT_ID

Where Trunc(poh.Creation_date) between NVL(:StartDate, TO_DATE('22.09.1992','dd.MM.yyyy')) and NVL(:EndDate, TO_DATE('22.09.2050','dd.MM.yyyy')) and 
pol.LINE_STATUS <> 'CANCELED'
) ProjectGraphV3

Group By ProjectGraphV3.Company, ProjectGraphV3.Project, ProjectGraphV3.Purc_Category_Name, ProjectGraphV3.ItemCategory_Name, ProjectGraphV3.ItemCategory_Name1, ProjectGraphV3.ItemCategory_Name2, ProjectGraphV3.ItemCategory_Name3, ProjectGraphV3.Month
Having (ProjectGraphV3.Project IN (:Project) OR 'All' IN (:Project || 'All')) and (ProjectGraphV3.Company IN (:Company) OR 'All' IN (:Company || 'All'))

Order By ProjectGraphV3.Month
-- and Sum(ProjectGraphV3.AmountUSD) = 0