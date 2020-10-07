Select

gledxb.Name as LedgerName,
poz.Vendor_Name,
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
        Inner Join POZ_SUPPLIERs_V poz
        ON poz.Vendor_ID = xlin.Party_ID
    ON xlin.gl_sl_link_table = glim.gl_sl_link_table and  xlin.gl_sl_link_id = glim.gl_sl_link_id 
ON glxb.je_header_id = glim.je_header_id and glxb.je_line_num = glim.je_line_num
Where (glxb.EFFECTIVE_DATE <= (:EndDate)) and (gledxb.Name = (:LedgerNameX)) 
and (valxb.Value IN (:Account) OR 'All' IN (:Account || 'All'))
and (poz.Vendor_Name IN (:VendorName) OR 'All' IN (:VendorName || 'All'))

Group By gledxb.Name, poz.Vendor_Name, valxb.Value, glxb.CURRENCY_CODE

Order By gledxb.Name, poz.Vendor_Name, valxb.Value, glxb.CURRENCY_CODE