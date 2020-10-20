SELECT
TBL_DemoDetials.ProjectName, 
TBL_DemoDetials.ProjectTaskName, 
TBL_DemoDetials.Account,
TBL_DemoDetials.Currency,

Sum(TBL_DemoDetials.OrderAmountWoutTax) OrderAmount,
Sum(TBL_DemoDetials.TaxAmount) OrderTaxAmount,
Sum(TBL_DemoDetials.TotalAmount) as OrderTotalAmount
From
(
SELECT
proc.SEGMENT1 as ProjectName,
proct.TASK_NAME as ProjectTaskName,
(glcode.Segment2 || ' - ' || valAccoutN.Description) as Account,
'TRY' as Currency,
(pod.TAX_EXCLUSIVE_AMOUNT * NVL(pod.Rate, 1)) as OrderAmountWoutTax,
(pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX) * NVL(pod.Rate, 1) as TaxAmount,
(pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX + pod.TAX_EXCLUSIVE_AMOUNT) * NVL(pod.Rate, 1) as TotalAmount

From PO_LINES_ALL pol
Inner Join PO_HEADERS_ALL poh 
ON pol.PO_HEADER_ID = poh.PO_HEADER_ID
Inner Join PO_DISTRIBUTIONS_ALL pod 
    Inner Join GL_CODE_COMBINATIONS glcode 
			Inner Join FND_VS_VALUES_B valAccout
                Inner Join FND_VS_VALUES_TL valAccoutN 
                ON valAccout.Value_Id = valAccoutN.Value_Id 
                and valAccoutN.LANGUAGE= FND_GLOBAL.Current_Language
		ON valAccout.Value = glcode.Segment2 and valAccout.ATTRIBUTE_CATEGORY = 'ACM_Account'
    ON pod.CODE_COMBINATION_ID  = glcode.CODE_COMBINATION_ID
ON pol.PO_LINE_ID = pod.PO_LINE_ID
Left Join PJF_PROJECTS_ALL_VL  proc ON proc.Project_Id = pod.PJC_PROJECT_ID
Left Join PJF_TASKS_V  proct ON proct.TASK_ID = pod.PJC_TASK_ID

Where pol.Line_Status in ('CLOSED','CLOSED FOR INVOICING', 'OPEN',  'CLOSED FOR RECEIVING')
and proc.SEGMENT1 like 'ACM Digital Demo%'

) TBL_DemoDetials

Group By TBL_DemoDetials.ProjectName, TBL_DemoDetials.ProjectTaskName, TBL_DemoDetials.Account, TBL_DemoDetials.Currency

Order By TBL_DemoDetials.ProjectTaskName