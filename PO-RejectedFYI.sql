-- FYI Order

Select LISTAGG(per.Username, '','') WITHIN GROUP (ORDER BY per.username) as Username From PO_ACTION_HISTORY pohis Inner Join PER_USERS per 	ON per.PERSON_ID = pohis.PERFORMER_ID and ((per.END_DATE is null) or (Trunc(Sysdate) Between per.START_DATE AND per.END_DATE)) Where pohis.CORRELATION_ID = (Select * From (Select pohisx.CORRELATION_ID From PO_ACTION_HISTORY pohisx Where pohisx.Object_Id = pohis.Object_Id and pohisx.ACTION_CODE = 'REJECT' Order By pohisx.SEQUENCE_NUM Desc) Where Rownum <= 1) and pohis.ACTION_CODE = ''APPROVE'' and pohis.Object_Id = '300000038355949'

orcl:query-database(concat('Select LISTAGG(per.Username, '','') WITHIN GROUP (ORDER BY per.username) as Username From PO_ACTION_HISTORY pohis Inner Join PER_USERS per 	ON per.PERSON_ID = pohis.PERFORMER_ID and ((per.END_DATE is null) or (Trunc(Sysdate) Between per.START_DATE AND per.END_DATE)) Where pohis.CORRELATION_ID = (Select * From (Select pohisx.CORRELATION_ID From PO_ACTION_HISTORY pohisx Where pohisx.Object_Id = pohis.Object_Id and pohisx.ACTION_CODE = ''REJECT'' Order By pohisx.SEQUENCE_NUM Desc) Where Rownum <= 1) and pohis.ACTION_CODE = ''APPROVE'' and pohis.Object_Id =',/task:task/task:payload/task:DocumentId),true(),true(),'jdbc/ApplicationDBDS')



Select LISTAGG(per.Username, '','') WITHIN GROUP (ORDER BY per.username) as Requester From POR_REQUISITION_LINES_ALL porreq Inner Join PER_USERS per ON per.PERSON_ID = porreq.Requester_Id and ((per.END_DATE is null) or (Trunc(Sysdate) Between per.START_DATE AND per.END_DATE)) Where porreq.PO_Header_Id = '300000038355949'

orcl:query-database(concat('Select LISTAGG(per.Username, '','') WITHIN GROUP (ORDER BY per.username) as Requester From POR_REQUISITION_LINES_ALL porreq Inner Join PER_USERS per ON per.PERSON_ID = porreq.Requester_Id and ((per.END_DATE is null) or (Trunc(Sysdate) Between per.START_DATE AND per.END_DATE)) Where porreq.PO_Header_Id =',/task:task/task:payload/task:DocumentId),true(),true(),'jdbc/ApplicationDBDS')
