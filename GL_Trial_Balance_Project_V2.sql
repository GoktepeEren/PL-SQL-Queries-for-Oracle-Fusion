Select

TableX.LedgerName, 
TableX.ValueThreeDescriptionTotal, 
TableX.Project, 
TableX.ValueDescTotal, 
TableX.Month,

Sum(TableX.AccountedDebit) as DB,
Sum(TableX.AccountedCredit) as CR,
Sum(TableX.AccountedBalances) as BL

From
(
Select

gledxb.Name as LedgerName,

-- Substr(valxb.Value,1,3) as ValueThree,

-- (Select valAccoutNX.Description
-- From FND_VS_VALUES_B valxbx
--         Inner Join FND_VS_VALUES_TL valAccoutNX 
--         ON valxbx.Value_Id = valAccoutNX.Value_Id and valAccoutNX.LANGUAGE= FND_GLOBAL.Current_Language
-- Where valxbx.Value = Substr(valxb.Value,1,3) and valxbx.ATTRIBUTE_CATEGORY = 'ACM_Account') as ValueThreeDescription,


(Substr(valxb.Value,1,3) || ' - ' ||
(Select valAccoutNXy.Description
From FND_VS_VALUES_B valxbxy
        Inner Join FND_VS_VALUES_TL valAccoutNXy 
        ON valxbxy.Value_Id = valAccoutNXy.Value_Id and valAccoutNXy.LANGUAGE= FND_GLOBAL.Current_Language
Where valxbxy.Value = Substr(valxb.Value,1,3) and valxbxy.ATTRIBUTE_CATEGORY = 'ACM_Account')) as ValueThreeDescriptionTotal,

proj.Segment1 as Project,

-- valxb.Value,
-- glxb.CURRENCY_CODE,

(valxb.Value || ' - ' ||valAccoutN.Description) ValueDescTotal,

TO_CHAR(glxb.EFFECTIVE_DATE, 'YYYY, MONTH') as Month,

-- Sum(NVL(glxb.ENTERED_DR,0)) as EnteredDebit,
-- Sum(NVL(glxb.ENTERED_CR,0)) as EnteredCredit,
-- Sum(NVL(glxb.ENTERED_DR,0)) - Sum(NVL(glxb.ENTERED_CR,0)) as EnteredBalances,

NVL(glxb.ACCOUNTED_DR,0) as AccountedDebit,
NVL(glxb.ACCOUNTED_CR,0) as AccountedCredit,
NVL(glxb.ACCOUNTED_DR,0) - NVL(glxb.ACCOUNTED_CR,0) AS AccountedBalances

From 
GL_JE_LINES glxb
Inner Join  GL_CODE_COMBINATIONS gcxb
    Inner Join FND_VS_VALUES_B valxb
        Inner Join FND_VS_VALUES_TL valAccoutN 
        ON valxb.Value_Id = valAccoutN.Value_Id 
        and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language
    ON valxb.Value = gcxb.Segment2 and valxb.ATTRIBUTE_CATEGORY = 'ACM_Account'
ON glxb.CODE_COMBINATION_ID = gcxb.CODE_COMBINATION_ID
Inner Join GL_LEDGERS gledxb
ON glxb.Ledger_Id = gledxb.Ledger_Id
Left Join GL_IMPORT_REFERENCES glim
    Left Join XLA_AE_LINES xlin
        Left Join PJF_PROJECTS_ALL_VL proj
        ON xlin.SR31 = proj.Project_ID
    ON xlin.gl_sl_link_table = glim.gl_sl_link_table and  xlin.gl_sl_link_id = glim.gl_sl_link_id 
ON glxb.je_header_id = glim.je_header_id and glxb.je_line_num = glim.je_line_num
Where (glxb.EFFECTIVE_DATE >= (:StartDate)) and (glxb.EFFECTIVE_DATE <= (:EndDate)) and (gledxb.Name = (:LedgerNameX)) 
and (valxb.Value IN (:Account) OR 'All' IN (:Account || 'All'))
and (proj.Segment1 IN (:Project) OR 'All' IN (:Project || 'All'))
) TableX

Group By  TableX.LedgerName, TableX.ValueThreeDescriptionTotal, TableX.Project, TableX.ValueDescTotal, TableX.Month

Order By  TableX.LedgerName, TableX.ValueThreeDescriptionTotal, TableX.Project, TableX.ValueDescTotal, TableX.Month
