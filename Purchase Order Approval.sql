SELECT 
Distinct
wf.tasknumber,
-- poh.Vendor_Id,
org.Name as Company,
poh.segment1,
poh.po_header_id,
approval_instance_id,
(CASE wf.state
When 'ASSIGNED' THEN 'InApproval / Onayda'
When 'INFO_REQUESTED' THEN 'Info Requested / Bilgi İstendi'
Else '-' 
End)
as Status,
poh.Creation_Date as CreationDate,
poh.SUBMIT_DATE as SubmitDate,
wf.assigneddate  as AssignedDate,
wf.assigneesdisplayname,
supp.vendor_name,
(pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX) as OrderTaxAmount,
pod.TAX_EXCLUSIVE_AMOUNT as OrderAmount,
(pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX  + pod.TAX_EXCLUSIVE_AMOUNT) as TotalOrderAmount,
poh.currency_code,
Case
When poh.Rate is null Then 1
Else poh.Rate
End as Rate,

((pod.RECOVERABLE_INCLUSIVE_TAX + pod.RECOVERABLE_TAX  + pod.TAX_EXCLUSIVE_AMOUNT) * 
Case
When poh.Rate is null Then 1
Else poh.Rate
End) as TotalOrderAmountDefCur,

(Select pohx.Currency_Code 
From po_headers_all pohx 
Where poh.BILLTO_BU_ID = pohx.BILLTO_BU_ID
and pohx.Rate is null
and rownum = 1) as OriginalCurrency,

-- pol.CREATED_BY as CreatedBy,
perf.Display_Name CreatedBy

FROM   PO_LINES_ALL pol
Inner Join po_headers_all poh 
	Inner Join po_versions pov 
		Inner Join fa_fusion_soainfra.wftask wf 
		ON ( pov.approval_instance_id = wf.compositeinstanceid
		AND ( wf.state = 'ASSIGNED' OR wf.state = 'INFO_REQUESTED' )
		AND wf.assignees IS NOT NULL
		AND wf.workflowpattern NOT IN ( 'AGGREGATION', 'FYI' )
		AND wf.componentname = 'DocumentApproval')	
	ON pov.po_header_id = poh.po_header_id AND pov.change_order_status = 'PENDING APPROVAL'
	Inner Join poz_suppliers_v supp
	On supp.vendor_id = poh.vendor_id
	Inner Join HR_ORGANIZATION_UNITS_F_TL org 
	On poh.BILLTO_BU_ID = org.ORGANIZATION_ID and org.Language = 'US'
ON pol.PO_HEADER_Id = poh.PO_HEADER_Id
INNER Join PO_DISTRIBUTIONS_ALL pod
ON pol.PO_LINE_ID = pod.PO_LINE_ID
Inner Join PER_USERS peru 
    Inner Join PER_PERSON_NAMES_F perf 
    ON peru.PERSON_ID = perf.PERSON_ID and perf.Name_Type = 'GLOBAL' and Trunc(sysdate) between perf.Effective_Start_Date and perf.Effective_End_Date
ON pol.CREATED_BY = peru.UserName
Where org.Name IN (:Company) 
and org.Name not like 'TR07%'
and poh.segment1 like '%' || (:OrderName) || '%'
and (supp.vendor_name IN (:Vendor) OR 'All' IN (:Vendor || 'All'))
and (perf.Display_Name IN (:Buyer) OR 'All' IN (:Buyer || 'All'))