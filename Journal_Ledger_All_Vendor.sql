Select 

glb.JE_BATCH_ID "Batch Id",
gll.JE_HEADER_ID "Header_Id",
gll.LEDGER_ID "Ledger_Id",
gll.CODE_COMBINATION_ID "Code_Id",
gled.Name "Ledger_Name",
gll.PERIOD_NAME "Period",
glb.NAME "Batch Name",
glb.DESCRIPTION "Batch Description",
glb.STATUS "Batch Status",
gll.EFFECTIVE_DATE "Effective Date",
glh.NAME "Journal Name",
glh.DESCRIPTION "Journal Description",
poz.Vendor_Name as SuppName,
supsite.PARTY_SITE_NAME as SuppSiteName,
glh.JE_SOURCE "Source",
glh.JE_CATEGORY "Category",
gll.JE_LINE_NUM"Line_Number",
gll.DESCRIPTION "Line_Description",
gcc.Segment2 "Account",
valAccoutNordist.Description as AccountDesc,
-- gll.ENTERED_DR "Entered Debit",
-- gll.ENTERED_CR "Entered Credit",

-- Sum(NVL(gll.ENTERED_DR,0) - NVL(gll.ENTERED_CR, 0))OVER(ORDER BY gll.EFFECTIVE_DATE, gll.JE_LINE_NUM) as Entered_Fark ,

gll.ACCOUNTED_DR "Accounted Debit",
gll.ACCOUNTED_CR "Accounted Crebit",

-- Sum(NVL(gll.ACCOUNTED_DR,0) - NVL(gll.ACCOUNTED_CR,0))OVER(ORDER BY gll.EFFECTIVE_DATE, gll.JE_LINE_NUM) as Accounting_Fark, 

gll.CURRENCY_CODE "Currency",

NVL(NVL(NVL(NVL(projGLlines.Segment1, projGLHeader.Segment1), proj.Segment1), projReceive.Segment1), 'Non-Project') as Project,

gll.CREATION_DATE, 

gll.CREATED_By,


per.Display_Name as CreatedFullName,

-- xlin.gl_sl_link_table,
-- xlin.gl_sl_link_id

NVL(NVL(xlin.SR28, proct.Task_Number), 'Non-Task') Task,

NVL(NVL(NVL(horg.Name, horgline.Name), horghead.Name), 'Non-Organization') ExpOrg

From  GL_JE_BATCHES glb
Inner Join GL_JE_HEADERS glh 
    Inner Join GL_JE_LINES gll
        Inner Join GL_LEDGERS gled
        ON gll.Ledger_Id = gled.Ledger_Id 
        Inner Join  GL_CODE_COMBINATIONS gcc
            Inner Join FND_VS_VALUES_B valAccoutordist
					Inner Join FND_VS_VALUES_TL valAccoutNordist
					ON valAccoutordist.Value_Id = valAccoutNordist.Value_Id 
					and valAccoutNordist.LANGUAGE = FND_GLOBAL.Current_Language
			ON valAccoutordist.Value = gcc.Segment2 and valAccoutordist.ATTRIBUTE_CATEGORY = 'ACM_Account'
        ON gll.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID
        Left Join GL_Import_References import
            Left Join XLA_AE_LINES xlin
                Left Join POZ_SUPPLIERs_V poz
                ON poz.Vendor_ID = xlin.Party_ID
                Left Join POZ_SUPPLIER_SITES_V supsite
                On xlin.Party_Site_ID = supsite.VENDOR_SITE_ID
                Left Join PJF_PROJECTS_ALL_VL proj
                ON xlin.SR31 = proj.Project_ID
                Left Join PJF_PROJECTS_ALL_VL projReceive
                ON TO_CHAR(xlin.SR7) = TO_CHAR(projReceive.Project_ID)
                Left Join HR_ORGANIZATION_V horg
                ON TO_CHAR(xlin.SR8) = To_Char(horg.ORGANIZATION_ID)  and horg.CLASSIFICATION_CODE='DEPARTMENT' and horg.STATUS='A' and horg.ATTRIBUTE3 like '%Direktörlük%'
                and Trunc(Sysdate) between Trunc(horg.EFFECTIVE_START_DATE) and Trunc(horg.EFFECTIVE_END_DATE)
            ON xlin.gl_sl_link_table = import.gl_sl_link_table and  xlin.gl_sl_link_id = import.gl_sl_link_id
        ON gll.JE_HEADER_ID  = import.JE_HEADER_ID and gll.JE_LINE_NUM = import.JE_LINE_NUM
        Left Join PER_USERS perus
            Inner Join PER_PERSON_NAMES_F_V per 
            ON perus.PERSON_ID = per.PERSON_ID
        ON perus.Username = gll.CREATED_By 
        -- GL Lines Project
        Left Join PJF_PROJECTS_ALL_VL projGLlines
        ON gll.Attribute1 = projGLlines.Project_ID
        Left Join PJF_TASKS_V  proct 
        ON gll.ATTRIBUTE3  = proct.TASK_ID
        Left Join HR_ORGANIZATION_V horgline
        ON gll.ATTRIBUTE6 = horgline.ORGANIZATION_ID  and horgline.CLASSIFICATION_CODE='DEPARTMENT' and horgline.STATUS='A' and horgline.ATTRIBUTE3 like '%Direktörlük%'
        and Trunc(Sysdate) between Trunc(horgline.EFFECTIVE_START_DATE) and Trunc(horgline.EFFECTIVE_END_DATE)
    On glh.JE_HEADER_ID = gll.JE_HEADER_ID
    -- GL Header Project
    -- AutoCopy - Manual - Spreadsheet
    Left Join PJF_PROJECTS_ALL_VL projGLHeader
    ON glh.Attribute_Number5 = projGLHeader.Project_ID
    Left Join HR_ORGANIZATION_V horghead
    ON glh.ATTRIBUTE_NUMBER4 = horghead.ORGANIZATION_ID  and horghead.CLASSIFICATION_CODE='DEPARTMENT' and horghead.STATUS='A' and horghead.ATTRIBUTE3 like '%Direktörlük%'
    and Trunc(Sysdate) between Trunc(horghead.EFFECTIVE_START_DATE) and Trunc(horghead.EFFECTIVE_END_DATE)
ON glb.JE_BATCH_ID = glh.JE_BATCH_ID

Where  
gled.Name IN (:LEDGER)
And gll.Status = 'P'

AND gll.PERIOD_NAME IN (:PERIOD)
-- AND glb.STATUS IN (:STATUS)
and (gcc.Segment2 IN (:ACCOUNT) OR 'All' IN (:ACCOUNT || 'All'))
And gll.EFFECTIVE_DATE between NVL((:StartDate),TO_DATE('01.01.1999','dd.MM.yyyy')) and NVL((:EndDate),TO_DATE('01.01.2500','dd.MM.yyyy')) 
and ((NVL(NVL(NVL(NVL(projGLlines.Segment1, projGLHeader.Segment1), proj.Segment1), projReceive.Segment1), 'Non-Project') IN (:Project)) OR 'All' IN (:Project || 'All'))
-- AND glh.JE_SOURCE IN (:SOURCE)
-- AND glh.JE_CATEGORY IN (:CATEGORY)
Order BY gll.EFFECTIVE_DATE, gll.JE_LINE_NUM

-- JLE Line
-- Task ATTRIBUTE3 -- OK
-- ExpOrg ATTRIBUTE6

-- JLE Header
-- ATTRIBUTE_NUMBER4
-- XLA SR8