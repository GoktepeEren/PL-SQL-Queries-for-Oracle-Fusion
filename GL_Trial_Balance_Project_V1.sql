Select

gledxb.Name as LedgerName,
proj.Segment1 as Project,
valxb.Value,
glxb.CURRENCY_CODE,

Sum(NVL(glxb.ENTERED_DR,0)) as EnteredDebit,
Sum(NVL(glxb.ENTERED_CR,0)) as EnteredCredit,
Sum(NVL(glxb.ENTERED_DR,0)) - Sum(NVL(glxb.ENTERED_CR,0)) as EnteredBalances,

Sum(NVL(glxb.ACCOUNTED_DR,0)) as AccountedDebit,
Sum(NVL(glxb.ACCOUNTED_CR,0)) as AccountedCredit,
Sum(NVL(glxb.ACCOUNTED_DR,0)) - Sum(NVL(glxb.ACCOUNTED_CR,0)) AS AccountedBalances

From 
GL_JE_LINES glxb
Inner Join  GL_CODE_COMBINATIONS gcxb
    Inner Join FND_VS_VALUES_B valxb
    ON valxb.Value = gcxb.Segment2 and valxb.ATTRIBUTE_CATEGORY = 'ACM_Account'
ON glxb.CODE_COMBINATION_ID = gcxb.CODE_COMBINATION_ID
Inner Join GL_LEDGERS gledxb
ON glxb.Ledger_Id = gledxb.Ledger_Id
Inner Join GL_IMPORT_REFERENCES glim
    Inner Join XLA_AE_LINES xlin
        Inner Join PJF_PROJECTS_ALL_VL proj
        ON xlin.SR31 = proj.Project_ID
    ON xlin.gl_sl_link_table = glim.gl_sl_link_table and  xlin.gl_sl_link_id = glim.gl_sl_link_id 
ON glxb.je_header_id = glim.je_header_id and glxb.je_line_num = glim.je_line_num
Where (glxb.EFFECTIVE_DATE >= (:StartDate)) and (glxb.EFFECTIVE_DATE <= (:EndDate)) and (gledxb.Name = (:LedgerNameX)) 
and (valxb.Value IN (:Account) OR 'All' IN (:Account || 'All'))
and (proj.Segment1 IN (:Project) OR 'All' IN (:Project || 'All'))

Group By gledxb.Name, proj.Segment1, valxb.Value, glxb.CURRENCY_CODE

Order By gledxb.Name, proj.Segment1, valxb.Value, glxb.CURRENCY_CODE