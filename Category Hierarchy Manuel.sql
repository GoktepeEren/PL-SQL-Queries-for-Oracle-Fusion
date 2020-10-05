Select

catex.Category_Name,
catex2.Category_Name SecondLevel,
catex3.Category_Name ThirdLevel,
catex4.Category_Name FourtLevel,
catex5.Category_Name FifthLevel

From
EGP_CATEGORY_SET_VALID_CATS cats
Inner Join EGP_CATEGORIES_VL catex 
ON cats.CATEGORY_ID = catex.Category_Id and catex.ENABLED_FLAG = 'Y' 
and catex.END_DATE_ACTIVE is null and catex.START_DATE_ACTIVE > TO_Date('30.05.2020','dd.MM.yyyy')
 
Left Join EGP_CATEGORY_SET_VALID_CATS cats2 
    Inner Join EGP_CATEGORIES_VL catex2 
    ON cats2.CATEGORY_ID = catex2.Category_Id and catex2.ENABLED_FLAG = 'Y' 
    and catex2.END_DATE_ACTIVE is null and catex2.START_DATE_ACTIVE > TO_Date('30.05.2020','dd.MM.yyyy')

    Left Join EGP_CATEGORY_SET_VALID_CATS cats3 
        Inner Join EGP_CATEGORIES_VL catex3 
        ON cats3.CATEGORY_ID = catex3.Category_Id and catex3.ENABLED_FLAG = 'Y' 
        and catex3.END_DATE_ACTIVE is null and catex3.START_DATE_ACTIVE > TO_Date('30.05.2020','dd.MM.yyyy')

        Left Join EGP_CATEGORY_SET_VALID_CATS cats4 
            Inner Join EGP_CATEGORIES_VL catex4 
            ON cats4.CATEGORY_ID = catex4.Category_Id and catex4.ENABLED_FLAG = 'Y' 
            and catex4.END_DATE_ACTIVE is null and catex4.START_DATE_ACTIVE > TO_Date('30.05.2020','dd.MM.yyyy')
    
            Left Join EGP_CATEGORY_SET_VALID_CATS cats5 
            Inner Join EGP_CATEGORIES_VL catex5 
            ON cats5.CATEGORY_ID = catex5.Category_Id and catex5.ENABLED_FLAG = 'Y' 
            and catex5.END_DATE_ACTIVE is null and catex5.START_DATE_ACTIVE > TO_Date('30.05.2020','dd.MM.yyyy')
    
            ON  cats4.Category_Id = cats5.Parent_Category_Id and cats4.CATEGORY_SET_ID = '300000013087480'

        ON  cats3.Category_Id = cats4.Parent_Category_Id and cats4.CATEGORY_SET_ID = '300000013087480'

    ON  cats2.Category_Id = cats3.Parent_Category_Id and cats3.CATEGORY_SET_ID = '300000013087480'

ON  cats.Category_Id = Cats2.Parent_Category_Id and cats2.CATEGORY_SET_ID = '300000013087480'

Where cats.CATEGORY_SET_ID = '300000013087480' and cats.Parent_Category_Id is null

Order By catex.Category_Name, catex2.Category_Name, catex3.Category_Name, catex4.Category_Name

