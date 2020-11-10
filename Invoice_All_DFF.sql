Select

  ent.NAME as Company,	
  
  ins.Invoice_Id as InvoiceId,
  ins.INVOICE_DATE as InvoiceDate,
  ins.CREATION_DATE as InvoiceCreationDate,
  ins.INVOICE_NUM as InvoiceNumber,
  ins.Invoice_Type_Lookup_Code as InvoiceType,
  sup.VENDOR_ID as SupplierId,
  sup.VENDOR_NAME as SuppName,
  
  ins.TOTAL_TAX_AMOUNT as InvTaxAmount,
  ins.INVOICE_AMOUNT as InvTotalAmount,

  Case
When ins.PAYMENT_STATUS_FLAG = 'P' Then 'Partial Paid' 
When ins.PAYMENT_STATUS_FLAG = 'Y' Then 'Paid' 
When ins.PAYMENT_STATUS_FLAG = 'N' Then 'Not Paid' 
End
as PaymentStatus,

  ins.INVOICE_CURRENCY_CODE as InvoiceCurrency,
  ins.PAYMENT_CURRENCY_CODE as PaymentCurrency,
  ins.Terms_Id  as TermId,
  term.Name as TermName,
   
  inl.PERIOD_NAME as Period,
  inl.LINE_NUMBER as LineNumber,
  inl.DESCRIPTION as ItemDesc,
  inl.LINE_TYPE_LOOKUP_CODE as LineType,
  inl.AMOUNT as LineAmount,
  inl.TAX_CLASSIFICATION_CODE as ItemTaxCode,
   
  inl.PO_HEADER_Id as OrderId,
  poh.Segment1 as OrderNumber,
  
  
  inl.PJC_PROJECT_ID as LineProjId,
  inl.PJC_ORGANIZATION_ID as LinePrjOrgId,
  
  dist.PJC_PROJECT_ID as DistProjId,
  dist.PJC_ORGANIZATION_ID as DistPrjOrgId,
  

  
   CASE
    WHEN inl.PJC_PROJECT_ID is not null THEN
		(Select 
			Distinct
			vl.Segment1
			From PJF_PROJECTS_ALL_VL vl
			Where inl.PJC_PROJECT_ID = vl.Project_ID)
	ELSE
		(Select 
			Distinct
			vl.Segment1
			From PJF_PROJECTS_ALL_VL vl
			Where dist.PJC_PROJECT_ID = vl.Project_ID)
	END as Project_Name,

	CASE
    WHEN inl.PJC_ORGANIZATION_ID is not null THEN
		(Select
			Distinct
			orge.Name
			From HR_ORGANIZATION_UNITS_F_TL orge
			Where orge.Language = 'US' and (Trunc(SysDate) between orge.EFFECTIVE_START_DATE and orge.EFFECTIVE_END_DATE)
			and orge.ORGANIZATION_ID = inl.PJC_ORGANIZATION_ID )
	When dist.PJC_ORGANIZATION_ID is not null Then
		(Select
			Distinct
			orgex.Name
			From
			HR_ORGANIZATION_UNITS_F_TL orgex
			Where orgex.Language = 'US' and (Trunc(SysDate) between orgex.EFFECTIVE_START_DATE and orgex.EFFECTIVE_END_DATE)
			and orgex.ORGANIZATION_ID = dist.PJC_ORGANIZATION_ID)
    Else ''
	END as Expenditure_Organization,



 --BusinessFunction --------------------------------------------
  
	CASE
    WHEN inl.ATTRIBUTE1 is not null THEN 
	 (Select 
		TL.Description
		From FND_VS_VALUES_B B,
		FND_VS_VALUES_TL TL
		WHERE B.VALUE_ID = TL.VALUE_ID 
		and B.Value = inl.ATTRIBUTE1
		and B.ATTRIBUTE_CATEGORY like 'ACM_Business_Function_VS' 
		and TL.LANGUAGE = fnd_Global.Current_Language)
    ELSE 
	 (Select 
		TL.Description
		From FND_VS_VALUES_B B,
		FND_VS_VALUES_TL TL
		WHERE B.VALUE_ID = TL.VALUE_ID 
		and B.Value = dist.ATTRIBUTE1
		and B.ATTRIBUTE_CATEGORY like 'ACM_Business_Function_VS' 
		and TL.LANGUAGE = fnd_Global.Current_Language)
    END as BusinessFunction,

--Project Old ------------------
  CASE
    WHEN inl.ATTRIBUTE2 is not null THEN 
		 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = inl.ATTRIBUTE2
			and B.ATTRIBUTE_CATEGORY like 'ACM_Project_VS' 
			and TL.LANGUAGE = fnd_Global.Current_Language)
    ELSE 
	 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = dist.ATTRIBUTE2
			and B.ATTRIBUTE_CATEGORY like 'ACM_Project_VS' 
			and TL.LANGUAGE = fnd_Global.Current_Language)
	End as ProjectOld,
	
	
-- Main Project--------------------------------------------

 CASE
    WHEN inl.ATTRIBUTE11 is not null  THEN 
		 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = inl.ATTRIBUTE11
			and B.ATTRIBUTE_CATEGORY like 'ACM_Project_VS_2' 
			and TL.LANGUAGE = fnd_Global.Current_Language)
    ELSE 
	 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = dist.ATTRIBUTE11
			and B.ATTRIBUTE_CATEGORY like 'ACM_Project_VS_2' 
			and TL.LANGUAGE = fnd_Global.Current_Language)
	End as Main_Project,
	
	
-- Sub Project--------------------------------------------

 CASE
    WHEN inl.ATTRIBUTE12 is not null  THEN 
		 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = inl.ATTRIBUTE12
			and B.ATTRIBUTE_CATEGORY like 'ACM_SubProject_VS' 
			and B.INDEPENDENT_VALUE = inl.ATTRIBUTE11
			and TL.LANGUAGE = fnd_Global.Current_Language)
    ELSE 
	 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = dist.ATTRIBUTE12
			and B.ATTRIBUTE_CATEGORY like 'ACM_SubProject_VS'
			and B.INDEPENDENT_VALUE = dist.ATTRIBUTE11
			and TL.LANGUAGE = fnd_Global.Current_Language)
	End as Sub_Project,
	
-- Process Type --------------------------------------------
	CASE
    WHEN inl.ATTRIBUTE13 is not null  THEN 
		 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = inl.ATTRIBUTE13
			and B.ATTRIBUTE_CATEGORY like 'ACM_ProcessType_VS' 
			and TL.LANGUAGE = fnd_Global.Current_Language)
    ELSE 
	 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = dist.ATTRIBUTE13
			and B.ATTRIBUTE_CATEGORY like 'ACM_ProcessType_VS' 
			and TL.LANGUAGE = fnd_Global.Current_Language)
	End as ProcessType,
	
-- Member Type --------------------------------------------
CASE
    WHEN inl.ATTRIBUTE6 is not null THEN 
		 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = inl.ATTRIBUTE6
			and B.ATTRIBUTE_CATEGORY like 'ACM_Member_Type_VS' 
			and TL.LANGUAGE = fnd_Global.Current_Language)
    ELSE 
	 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = dist.ATTRIBUTE6
			and B.ATTRIBUTE_CATEGORY like 'ACM_Member_Type_VS' 
			and TL.LANGUAGE = fnd_Global.Current_Language)
	End as Member_Type,
	

-- Member --------------------------------------------
CASE
    WHEN inl.ATTRIBUTE7 is not null  THEN 
		 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = inl.ATTRIBUTE7
			and B.ATTRIBUTE_CATEGORY like 'ACM_Member_VS' 
			and B.INDEPENDENT_VALUE = inl.ATTRIBUTE6
			and TL.LANGUAGE = fnd_Global.Current_Language)
    ELSE 
	 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = dist.ATTRIBUTE7
			and B.ATTRIBUTE_CATEGORY like 'ACM_Member_VS'
			and B.INDEPENDENT_VALUE = dist.ATTRIBUTE6
			and TL.LANGUAGE = fnd_Global.Current_Language)
	End as Member,	  
	
-- Place --------------------------------------------
CASE
    WHEN inl.ATTRIBUTE8 is not null  THEN 
		 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = inl.ATTRIBUTE8
			and B.ATTRIBUTE_CATEGORY like 'ACM_Place_VS' 
			and TL.LANGUAGE = fnd_Global.Current_Language)
    ELSE 
	 (Select 
			TL.Description
			From FND_VS_VALUES_B B,
			FND_VS_VALUES_TL TL
			WHERE B.VALUE_ID = TL.VALUE_ID 
			and B.Value = dist.ATTRIBUTE8
			and B.ATTRIBUTE_CATEGORY like 'ACM_Place_VS'
			and TL.LANGUAGE = fnd_Global.Current_Language)
	End as Place,
	
    paf.PERSON_NUMBER as Personal_Number,
	pername.FULL_NAME as Personal,

  --inl.CREATION_DATE as CreationDate,
  inl.CREATED_BY as CreationUser,
 TO_CHAR(inl.CREATION_DATE, 'dd.MM.yyyy')  as CreateDate,
  
  dist.DIST_CODE_COMBINATION_ID codeId,
  inl.DEFAULT_DIST_CCID as codeid2,
  glcode.Segment2 as Account,

(Select
		valAccoutN.Description
		From FND_VS_VALUES_B valAccout 
		Inner Join FND_VS_VALUES_TL valAccoutN 
		ON valAccout.Value_Id = valAccoutN.Value_Id 
		and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language
        Where valAccout.Value = glcode.Segment2 
		and valAccout.ATTRIBUTE_CATEGORY like 'ACM_Account'
  ) as AccountDescription

  

FROM
  
AP_INVOICES_ALL ins 

INNER JOIN AP_INVOICE_LINES_ALL inl
    Left Join PER_ALL_PEOPLE_F paf 
        Inner Join PER_PERSON_NAMES_F pername 
        ON pername.PERSON_ID = paf.PERSON_ID
        AND TRUNC(SYSDATE) BETWEEN pername.EFFECTIVE_START_DATE AND pername.EFFECTIVE_END_DATE AND pername.NAME_TYPE = 'GLOBAL'
    ON inl.Attribute15 = paf.PERSON_NUMBER AND TRUNC(SYSDATE) BETWEEN paf.EFFECTIVE_START_DATE AND paf.EFFECTIVE_END_DATE
On ins.INVOICE_ID = inl.INVOICE_ID
Left Join PO_HEADERS_ALL poh On inl.PO_HEADER_Id = poh.PO_HEADER_Id
Left Join AP_INVOICE_DISTRIBUTIONS_ALL dist 
   
ON (dist.INVOICE_ID = inl.Invoice_Id and  dist.INVOICE_LINE_NUMBER = inl.LINE_NUMBER) and dist.Amount > 0

-- Get Account Informations from line not distributions
Left Join GL_CODE_COMBINATIONS glcode 
    Inner Join FND_VS_VALUES_B valAccout
		Inner Join FND_VS_VALUES_TL valAccoutN 
		ON valAccout.Value_Id = valAccoutN.Value_Id 
		and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language	
	ON valAccout.Value = glcode.Segment2 and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
ON glcode.CODE_COMBINATION_ID = inl.DEFAULT_DIST_CCID 

Inner Join POZ_SUPPLIERS_V sup On sup.VENDOR_ID = ins.VENDOR_ID
Inner Join XLE_ENTITY_PROFILES ent On ent.LEGAL_ENTITY_ID = ins.LEGAL_ENTITY_ID	
Inner Join AP_TERMS_TL term ON term.TERM_ID = ins.TERMS_ID And term.LANGUAGE = fnd_Global.Current_Language 

Where 
-- ins.INVOICE_TYPE_LOOKUP_CODE = 'STANDARD'
-- and inl.LINE_TYPE_LOOKUP_CODE  = 'ITEM'
inl.CANCELLED_FLAG = 'N'

and ent.NAME like '%' || :Company || '%' 
and ins.Invoice_DATE Between NVL(:InvoiceStartDate, to_Date('22.09.1992','dd.MM.yyyy')) and NVL(:InvoiceEndDate, to_Date('22.09.2192','dd.MM.yyyy'))  
and ins.INVOICE_NUM like '%' || :InvoiceNumber || '%'
-- and ins.INVOICE_NUM  = 'BORDRO-4-2020-TR01_V6'

Order By   ins.INVOICE_DATE, ins.INVOICE_ID, inl.LINE_NUMBER