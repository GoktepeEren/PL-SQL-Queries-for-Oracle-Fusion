Select
abse.PER_ABSENCE_ENTRY_ID KEY,
'Absence_PrintOut_Form' TEMPLATE,
'XPT' TEMPLATE_FORMAT,
'en-US' LOCALE,
'PDF' OUTPUT_FORMAT,
'EMAIL' DEL_CHANNEL,
tbl_email.EMAIL_ADDRESS PARAMETER1,
'darknightx@xyz.com' PARAMETER3,
'Absence Document / İzin Belgesi ' || perf.DISPLAY_NAME || ' ' || TO_CHAR(abse.START_DATE,'DD.MM.YYYY') || ' - ' || TO_CHAR(abse.End_DATE,'DD.MM.YYYY') as PARAMETER4,

-- Email Body
'Hi ' || perf.DISPLAY_NAME || ',' || CHR(13)
|| 'You can see approved absence information details as an attachment.' || CHR(13) 
|| 'You need to get print-out of the attachment. You must sign and deliver the document to HR Department' || CHR(13) 
|| 'Absence Information ; ' || CHR(13)
|| 'Start Date :' || TO_CHAR(abse.START_DATE,'DD.MM.YYYY') || CHR(13)
|| 'End Date :' || TO_CHAR(abse.END_DATE,'DD.MM.YYYY') || CHR(13)
|| 'Total :' || TRUNC(abse.DURATION,3) || ' Days' || CHR(13) || CHR(13) || CHR(13)
|| '--------'
|| CHR(13) || 'Selamlar ' || perf.DISPLAY_NAME || ',' || CHR(13)
|| 'Onaylanmış izin belgeni ekte görebilirsin.' || CHR(13) 
|| 'Ekteki izin belgesinin çıktısını almanız gerekiyor.' || CHR(13)
|| 'Sonrasında imzalamalı ve İnsan Kaynakları departmanına teslim etmelisiniz.' || CHR(13) 
|| 'İzin Bilgileri ; ' || CHR(13)
|| 'Başlangıç Tarihi : ' || TO_CHAR(abse.START_DATE,'DD.MM.YYYY') || CHR(13)
|| 'Bitiş Tarihi     : ' || TO_CHAR(abse.END_DATE,'DD.MM.YYYY') || CHR(13)
|| 'Toplam           : ' || TRUNC(abse.DURATION,3) || ' Gün' || CHR(13) as PARAMETER5,
'True' PARAMETER6

From 
ANC_PER_ABS_ENTRIES abse
Inner Join PER_PERSON_NAMES_F perf ON abse.Person_Id = perf.Person_Id 
AND SYSDATE BETWEEN perf.EFFECTIVE_START_DATE AND perf.EFFECTIVE_END_DATE and perf.Name_Type = 'GLOBAL'
Inner Join PER_EMAIL_ADDRESSES tbl_email ON abse.Person_Id = tbl_email.PERSON_ID and tbl_email.EMAIL_TYPE = 'W1'


Order By abse.Creation_Date DESC