Select

gllb.LedgerName as LedgerName,

valAccoutordistb.Value as Account,

valAccoutNordistb.DESCRIPTION as AccountDesc,

-- Sum(NVL(gllb.ACCOUNTED_DR,0)) as AccountedDebit,
-- Sum(NVL(gllb.ACCOUNTED_CR,0)) as AccountedCrebit,
TO_CHAR(gllb.EFFECTIVE_DATE, 'YYYY, MONTH') as Month,

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
            glxb.EFFECTIVE_DATE,
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
    ON valAccoutordistb.Value = SUBSTR(gllb.Value, 1, Length(valAccoutordistb.Value)) 

Where valAccoutordistb.ATTRIBUTE_CATEGORY = 'ACM_Account' 
-- Getting All Account
and (valAccoutordistb.Value IN (:Account) OR 'All' IN (:Account || 'All'))

-- Getting accounts at a Certain Interval  
and (Cast(regexp_replace(SUBSTR(valAccoutordistb.Value,'1','1'), '[^0-9]+', '') as number) between NVL(To_Number(SUBSTR(To_Char(:StartValue),'1','1')),0) and NVL(To_Number(SUBSTR(To_Char(:EndValue),'1','1')),999999999999))
and (Cast(regexp_replace(valAccoutordistb.Value, '[^0-9]+', '') as number) between NVL(To_Number(:StartValue),0) and NVL(To_Number(:EndValue),999999999999))

-- Getting Level Account
and LENGTH(To_Char((cast(regexp_replace(valAccoutordistb.Value, '[^0-9]+', '') as number)))) 
between (Case When NVL(To_Number(:LevelNumber),0) = 0 Then 0 Else (Case When NVL(To_Number(:LevelNumber),4) > 4 Then 12 Else NVL(To_Number(:LevelNumber),4) * 3 End ) End) and (Case When NVL(To_Number(:LevelNumber),0) = 0 Then 12 Else (Case When NVL(To_Number(:LevelNumber),4) > 4 Then 12 Else NVL(To_Number(:LevelNumber),4) * 3 End ) End) 
Group By gllb.LedgerName, valAccoutordistb.Value, valAccoutNordistb.DESCRIPTION, TO_CHAR(gllb.EFFECTIVE_DATE, 'YYYY, MONTH')

Order By valAccoutordistb.Value