Select
gllb.LedgerName as LedgerName,

-- valAccoutordistb.Value as Account,

valAccoutordistb.Value as Account,

valAccoutNordistb.DESCRIPTION as AccountDesc,

Sum(NVL(gllb.ENTERED_DR,0)) as EnteredDebit,
Sum(NVL(gllb.ENTERED_CR,0)) as EnteredCredit,
Sum(NVL(gllb.ENTERED_DR,0)) - Sum(NVL(gllb.ENTERED_CR,0)) as EnteredBalance,

Sum(NVL(gllb.ACCOUNTED_DR,0)) as AccountedDebit,
Sum(NVL(gllb.ACCOUNTED_CR,0)) as AccountedCrebit,
Sum(NVL(gllb.ACCOUNTED_DR,0)) - Sum(NVL(gllb.ACCOUNTED_CR,0)) as AccountedBalance

From FND_VS_VALUES_B valAccoutordistb
    Inner Join FND_VS_VALUES_TL valAccoutNordistb
    ON valAccoutordistb.Value_Id = valAccoutNordistb.Value_Id 
    and valAccoutNordistb.LANGUAGE = FND_GLOBAL.Current_Language
    Inner Join 
            (Select
            -- Distinct
            valxb.Value,
            glxb.ENTERED_DR,
            glxb.ENTERED_CR,
            glxb.ACCOUNTED_DR,
            glxb.ACCOUNTED_CR,
            gledxb.Name as LedgerName
            From 
            GL_JE_LINES glxb
            Inner Join  GL_CODE_COMBINATIONS gcxb
                Inner Join FND_VS_VALUES_B valxb
                ON valxb.Value = gcxb.Segment2 and valxb.ATTRIBUTE_CATEGORY = 'ACM_Account'
            ON glxb.CODE_COMBINATION_ID = gcxb.CODE_COMBINATION_ID
            Inner Join GL_LEDGERS gledxb
            ON glxb.Ledger_Id = gledxb.Ledger_Id
            Where glxb.EFFECTIVE_DATE between :StartDate and :EndDate
            and gledxb.Name = :LedgerNameX) gllb
            -- Inner Join GL_JE_HEADERS glh
            --     Inner Join GL_JE_BATCHES glb
            --     ON glb.JE_BATCH_ID = glh.JE_BATCH_ID
            -- On glh.JE_HEADER_ID = gll.JE_HEADER_ID
    ON valAccoutordistb.Value = SUBSTR(gllb.Value, 1, Length(valAccoutordistb.Value)) 

Where valAccoutordistb.ATTRIBUTE_CATEGORY = 'ACM_Account' 
and (valAccoutordistb.Value IN (:Account) OR 'All' IN (:Account || 'All'))
Group By gllb.LedgerName, valAccoutordistb.Value, valAccoutNordistb.DESCRIPTION

Order By valAccoutordistb.Value