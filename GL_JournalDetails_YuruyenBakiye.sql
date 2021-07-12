Select

GLDetail.AE_HEADER_ID,
GLDetail.AE_LINE_NUM,
GLDetail.Invoice_Num,
GLDetail.LedgerName,
GLDetail.Period,
GLDetail.BatchName,
GLDetail.BatchDescription,
GLDetail.BatchStatus,
GLDetail.EffectiveDate,
GLDetail.JournalName,
GLDetail.JournalDescription,
GLDetail.SuppName,
GLDetail.SuppSiteName,
GLDetail.Source,
GLDetail.Category,
GLDetail.LineNumber,
GLDetail.LineDescription,
GLDetail.Status,
GLDetail.SeqNumber,
GLDetail.AccountThree,
GLDetail.Account,
GLDetail.AccountDesc,
GLDetail.AccountedDebit,
GLDetail.AccountedCrebit,
GLDetail.Balance,
Sum(GLDetail.Balance) Over (Order By GLDetail.EffectiveDate, GLDetail.JournalName, GLDetail.LineNumber) as YuruyenBalance,
GLDetail.EnteredDebit,
GLDetail.EnteredCrebit,
GLDetail.EnteredBalance,
GLDetail.Currency,
GLDetail.Project,
GLDetail.Task,
GLDetail.ExpOrg,
GLDetail.CREATION_DATE,
GLDetail.CREATED_By,
GLDetail.CreatedFullName


From


(Select 
xlin.AE_HEADER_ID,
xlin.AE_LINE_NUM,


gled.Name as LedgerName,

glb.NAME as BatchName,
Translate(glb.Description, chr(10)||chr(11)||chr(13), '   ') as BatchDescription,
glb.STATUS as BatchStatus,

glh.NAME as JournalName,
Translate(glh.Description, chr(10)||chr(11)||chr(13), '   ') as JournalDescription,
glh.JE_SOURCE as Source,
glh.JE_CATEGORY as Category,
glh.POSTING_ACCT_SEQ_VALUE as SeqNumber,

gll.PERIOD_NAME as Period,
gll.EFFECTIVE_DATE as EffectiveDate,
gll.JE_LINE_NUM as LineNumber,
Translate(gll.Description, chr(10)||chr(11)||chr(13), '   ')  as LineDescription,
gll.CURRENCY_CODE as Currency,
gll.Status as Status,
gll.CREATION_DATE, 
gll.CREATED_By,

NVL(gll.ENTERED_DR, 0) EnteredDebit,
NVL(gll.ENTERED_CR, 0) EnteredCrebit,
NVL(gll.ENTERED_DR, 0) - NVL(gll.ENTERED_CR, 0) EnteredBalance,

NVL(gll.ACCOUNTED_DR, 0) AccountedDebit,
NVL(gll.ACCOUNTED_CR, 0) AccountedCrebit,
NVL(gll.ACCOUNTED_DR, 0) - NVL(gll.ACCOUNTED_CR, 0) Balance,

poz.Vendor_Name as SuppName,
supsite.PARTY_SITE_NAME as SuppSiteName,

Case 
When glh.JE_SOURCE = 'Assets' 
-- and glh.JE_CATEGORY = 'Depreciation' 
Then 
(Select aia.Asset_Number From XLA_DISTRIBUTION_LINKS xlad
    Left Join FA_ADDITIONS_B aia ON aia.ASSET_ID = xlad.SOURCE_DISTRIBUTION_ID_NUM_1
Where xlad.AE_HEADER_ID = xlin.AE_HEADER_ID AND xlad.AE_LINE_NUM = xlin.AE_LINE_NUM AND xlad.EVENT_CLASS_CODE = 'DEPRECIATION' and Rownum <= 1 )

Else
(Select aia.Invoice_Num From XLA_DISTRIBUTION_LINKS xlad
    Left Join AP_INVOICES_ALL aia ON aia.INVOICE_ID = xlad.APPLIED_TO_SOURCE_ID_NUM_1
Where xlad.AE_HEADER_ID = xlin.AE_HEADER_ID AND xlad.AE_LINE_NUM = xlin.AE_LINE_NUM AND xlad.EVENT_CLASS_CODE = 'INVOICES' and Rownum <= 1 )
End
as Invoice_Num,

Substr(gcc.Segment2,1,3) AccountThree,
gcc.Segment2 Account,
valAccoutNordist.Description as AccountDesc,

NVL(NVL(NVL(NVL(projGLlines.Segment1, projGLHeader.Segment1), proj.Segment1), projReceive.Segment1), 'Non-Project') as Project,

NVL(NVL(xlin.SR28, proct.Task_Number), 'Non-Task') Task,

NVL(NVL(NVL(horg.Name, horgline.Name), horghead.Name), 'Non-Organization') ExpOrg,

per.Display_Name as CreatedFullName

-- xlin.gl_sl_link_table,
-- xlin.gl_sl_link_id

From GL_JE_LINES gll
        
    Inner Join GL_JE_HEADERS glh 

        Inner Join GL_JE_BATCHES glb
        ON glb.JE_BATCH_ID = glh.JE_BATCH_ID

        -- GL Header Project
        -- AutoCopy - Manual - Spreadsheet
        Left Join PJF_PROJECTS_ALL_VL projGLHeader
        ON To_Char(glh.Attribute_Number5) = To_Char(projGLHeader.Project_ID)
        Left Join HR_ORGANIZATION_V horghead
        ON glh.ATTRIBUTE_NUMBER4 = horghead.ORGANIZATION_ID  and horghead.CLASSIFICATION_CODE='DEPARTMENT' and horghead.STATUS='A' and horghead.ATTRIBUTE3 like '%Direktörlük%'
        and Trunc(Sysdate) between Trunc(horghead.EFFECTIVE_START_DATE) and Trunc(horghead.EFFECTIVE_END_DATE)

    On glh.JE_HEADER_ID = gll.JE_HEADER_ID

    Inner Join GL_LEDGERS gled
    ON gll.Ledger_Id = gled.Ledger_Id 
        
    Inner Join  GL_CODE_COMBINATIONS gcc
        Inner Join FND_VS_VALUES_B valAccoutordist
				Inner Join FND_VS_VALUES_TL valAccoutNordist
				ON valAccoutordist.Value_Id = valAccoutNordist.Value_Id 
				and valAccoutNordist.LANGUAGE = FND_GLOBAL.Current_Language
		ON valAccoutordist.Value = gcc.Segment2 and valAccoutordist.ATTRIBUTE_CATEGORY = 'ACM_Account'
    ON gll.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID
        
    -- Left Join GL_Import_References import
    --     Left Join XLA_AE_LINES xlin
    --         Left Join POZ_SUPPLIERs_V poz
    --         ON poz.Vendor_ID = xlin.Party_ID
    --         Left Join POZ_SUPPLIER_SITES_V supsite
    --         On xlin.Party_Site_ID = supsite.VENDOR_SITE_ID
    --         Left Join PJF_PROJECTS_ALL_VL proj
    --         ON To_Char(xlin.SR31) = To_Char(proj.Project_ID)
    --         Left Join PJF_PROJECTS_ALL_VL projReceive
    --         ON TO_CHAR(xlin.SR7) = TO_CHAR(projReceive.Project_ID)
    --         Left Join HR_ORGANIZATION_V horg
    --         ON TO_CHAR(xlin.SR8) = To_Char(horg.ORGANIZATION_ID)  and horg.CLASSIFICATION_CODE='DEPARTMENT' and horg.STATUS='A' and horg.ATTRIBUTE3 like '%Direktörlük%'
    --         and Trunc(Sysdate) between Trunc(horg.EFFECTIVE_START_DATE) and Trunc(horg.EFFECTIVE_END_DATE)
    --     ON xlin.gl_sl_link_table = import.gl_sl_link_table and  xlin.gl_sl_link_id = import.gl_sl_link_id
    -- ON gll.JE_HEADER_ID  = import.JE_HEADER_ID and gll.JE_LINE_NUM = import.JE_LINE_NUM
    Left Join XLA_AE_LINES xlin
        Left Join POZ_SUPPLIERs_V poz
        ON poz.Vendor_ID = xlin.Party_ID
        Left Join POZ_SUPPLIER_SITES_V supsite
        On xlin.Party_Site_ID = supsite.VENDOR_SITE_ID
        Left Join PJF_PROJECTS_ALL_VL proj
        ON To_Char(xlin.SR31) = To_Char(proj.Project_ID)
        Left Join PJF_PROJECTS_ALL_VL projReceive
        ON TO_CHAR(xlin.SR7) = TO_CHAR(projReceive.Project_ID)
        Left Join HR_ORGANIZATION_V horg
        ON TO_CHAR(xlin.SR8) = To_Char(horg.ORGANIZATION_ID)  and horg.CLASSIFICATION_CODE='DEPARTMENT' and horg.STATUS='A' and horg.ATTRIBUTE3 like '%Direktörlük%'
        and Trunc(Sysdate) between Trunc(horg.EFFECTIVE_START_DATE) and Trunc(horg.EFFECTIVE_END_DATE)
    ON xlin.AE_HEADER_ID = gll.REFERENCE_7 and  xlin.AE_LINE_NUM = gll.REFERENCE_8
    Left Join PER_USERS perus
         Inner Join PER_PERSON_NAMES_F per 
        ON perus.PERSON_ID = per.PERSON_ID and per.Name_Type = 'GLOBAL' and Trunc(Sysdate) between per.EFFECTIVE_START_DATE and per.EFFECTIVE_End_DATE
    ON perus.Username = gll.CREATED_By 
    -- GL Lines Project
    Left Join PJF_PROJECTS_ALL_VL projGLlines
    ON To_Char(gll.Attribute1) = To_Char(projGLlines.Project_ID)
    Left Join PJF_TASKS_V  proct 
    ON gll.ATTRIBUTE3  = proct.TASK_ID
    Left Join HR_ORGANIZATION_V horgline
    ON gll.ATTRIBUTE6 = horgline.ORGANIZATION_ID  and horgline.CLASSIFICATION_CODE='DEPARTMENT' and horgline.STATUS='A' and horgline.ATTRIBUTE3 like '%Direktörlük%'
    and Trunc(Sysdate) between Trunc(horgline.EFFECTIVE_START_DATE) and Trunc(horgline.EFFECTIVE_END_DATE)
) GLDetail


Where  
GLDetail.LedgerName IN (:LEDGER)
and GLDetail.Status IN (:AccountingStatus)  
and (GLDetail.Period IN (:PERIOD) OR 'All' IN (:PERIOD || 'All'))

and (GLDetail.Account IN (:ACCOUNT) OR 'All' IN (:ACCOUNT || 'All'))
And GLDetail.EffectiveDate between NVL((:StartDate),TO_DATE('01.01.1999','dd.MM.yyyy')) and NVL((:EndDate),TO_DATE('01.01.2500','dd.MM.yyyy')) 
and (GLDetail.Project IN (:Project) OR 'All' IN (:Project || 'All'))
and (GLDetail.ExpOrg IN (:ExpOrg) OR 'All' IN (:ExpOrg || 'All'))

Order By GLDetail.EffectiveDate, GLDetail.JournalName, GLDetail.LineNumber