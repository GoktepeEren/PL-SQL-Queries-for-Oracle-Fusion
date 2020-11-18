Select 

proj.LEGAL_ENTITY_ID,
proj.PROJECT_ID ProjectId,
org.Name as Company,
proj.SEGMENT1 ProjectNumber,
proj.NAME ProjectName,
-- projman.Person_Name ProjectManager,
proj.PROJECT_STATUS_CODE ProjectStatus,
proj.START_DATE ProjectStart,
projcodemainp.Meaning MainProject,
projcodeloca.Meaning ProjectLocation,
projcodecont.Meaning ProjectContentType,
projel.Text_Attr01 Season

From

PJF_PROJECTS_ALL_VL proj
    Inner Join XLE_ENTITY_PROFILES org 
    On proj.LEGAL_ENTITY_ID = org.LEGAL_ENTITY_ID 
    Inner Join PJF_PROJ_ELEMENTS_VL projel
        Left Join PJT_COLUMN_LKP_VALUES_VL projcodemainp ON projel.TASK_CODE01_ID = projcodemainp.Code_value_Id and projcodemainp.Column_Map_Id = '300000011071779'
        Left Join PJT_COLUMN_LKP_VALUES_VL projcodeloca ON projel.TASK_CODE02_ID = projcodeloca.Code_value_Id and projcodeloca.Column_Map_Id = '300000020011425'
        Left Join PJT_COLUMN_LKP_VALUES_VL projcodecont ON projel.TASK_CODE03_ID = projcodecont.Code_value_Id and projcodecont.Column_Map_Id = '300000028309790'
    On projel.Project_Id = proj.Project_Id
    -- Inner Join PRJ_PROJECT_MANAGER_V projman 
    -- ON projman.Project_Id = proj.Project_Id
where proj.PROJECT_STATUS_CODE <> 'DRAFT'

