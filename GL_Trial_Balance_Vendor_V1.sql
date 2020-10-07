Select
jle.LedgerName,
poz.Vendor_Name,
jle.Value,
jle.EnteredDebit,
jle.EnteredCredit,
jle.EnteredBalances,
jle.AccountedDebit,
jle.AccountedCredit,
jle.AccountedBalances
From 
POZ_SUPPLIERS_V poz 
Inner Join 
    (Select
    gledxb.Name as LedgerName,
    xlin.Party_ID,
    valxb.Value,
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
        ON xlin.gl_sl_link_table = glim.gl_sl_link_table and  xlin.gl_sl_link_id = glim.gl_sl_link_id and xlin.Party_ID is not null
    ON glxb.je_header_id = glim.je_header_id and glxb.je_line_num = glim.je_line_num
    Where glxb.EFFECTIVE_DATE <= (:EndDate) and gledxb.Name = (:LedgerNameX) 
    and (valxb.Value IN (:Account) OR 'All' IN (:Account || 'All'))
    Group By gledxb.Name, xlin.Party_ID, valxb.Value) jle

ON poz.Vendor_ID = jle.Party_ID 
Where  (poz.Vendor_Name IN (:VendorName) OR 'All' IN (:VendorName || 'All'))
Order By poz.Vendor_Name, jle.Value