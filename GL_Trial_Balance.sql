Select
*
From 
(Select
gll.LedgerName as LedgerName,

valAccoutordist.Value as Account,

valAccoutNordist.DESCRIPTION as AccountDesc,

Sum(NVL(gll.ENTERED_DR,0)) as EnteredDebit,
Sum(NVL(gll.ENTERED_CR,0)) as EnteredCredit,
Sum(NVL(gll.ENTERED_DR,0)) - Sum(NVL(gll.ENTERED_CR,0)) as EnteredBalance,

Sum(NVL(gll.ACCOUNTED_DR,0)) as AccountedDebit,
Sum(NVL(gll.ACCOUNTED_CR,0)) as AccountedCrebit,
Sum(NVL(gll.ACCOUNTED_DR,0)) - Sum(NVL(gll.ACCOUNTED_CR,0)) as AccountedBalance

From FND_VS_VALUES_B valAccoutordist
    Inner Join FND_VS_VALUES_TL valAccoutNordist
    ON valAccoutordist.Value_Id = valAccoutNordist.Value_Id 
    and valAccoutNordist.LANGUAGE = FND_GLOBAL.Current_Language
    Inner Join 
            (Select
             -- Distinct
            valx.Value,
            glx.ENTERED_DR,
            glx.ENTERED_CR,
            glx.ACCOUNTED_DR,
            glx.ACCOUNTED_CR,
            gledx.Name as LedgerName
            From 
            GL_JE_LINES glx
            Inner Join  GL_CODE_COMBINATIONS gcx
                Inner Join FND_VS_VALUES_B valx
                ON valx.Value = gcx.Segment2 and valx.ATTRIBUTE_CATEGORY = 'ACM_Account'
            ON glx.CODE_COMBINATION_ID = gcx.CODE_COMBINATION_ID
            Inner Join GL_LEDGERS gledx
            ON glx.Ledger_Id = gledx.Ledger_Id
            Where glx.EFFECTIVE_DATE between :StartDate and :EndDate
            and gledx.Name = :LedgerNameX) gll 
            -- Inner Join GL_JE_HEADERS glh
            --     Inner Join GL_JE_BATCHES glb
            --     ON glb.JE_BATCH_ID = glh.JE_BATCH_ID
            -- On glh.JE_HEADER_ID = gll.JE_HEADER_ID
    ON valAccoutordist.Value = SUBSTR(gll.Value, 1, Length(valAccoutordist.Value)) 

Where valAccoutordist.ATTRIBUTE_CATEGORY = 'ACM_Account' and (:Account) is null
Group By gll.LedgerName, valAccoutordist.Value, valAccoutNordist.DESCRIPTION
Order By valAccoutordist.Value)

Union All
Select
*
From
(Select
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

Where valAccoutordistb.ATTRIBUTE_CATEGORY = 'ACM_Account' and (:Account) is not null
and valAccoutordistb.Value IN (:Account)
Group By gllb.LedgerName, valAccoutordistb.Value, valAccoutNordistb.DESCRIPTION

Order By valAccoutordistb.Value)