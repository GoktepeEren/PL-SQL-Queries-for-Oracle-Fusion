Select
fnd_tax.Lookup_Code,
fnd_tax.LOOKUP_TYPE,
fnd_tax.Language,
fnd_tax.Source_Lang,
fnd_tax.Enabled_Flag,
fnd_tax.Start_Date_Active,
fnd_tax.End_Date_Active,
fnd_set.SET_CODE,
fnd_set.Set_Name
From
FND_LOOKUP_VALUES fnd_tax
    Inner Join FND_SETID_SETS_VL fnd_set  
    ON fnd_tax.Set_Id = fnd_set.Set_Id 
Where fnd_tax.LOOKUP_TYPE =  'ZX_INPUT_CLASSIFICATIONS'
and fnd_tax.Language In (:LanguageTax) and fnd_tax.Source_Lang IN (:SourLanguageTax)
Order By fnd_tax.Creation_Date DESC
