-- Fianacial Analyst Role With Ledger Id -- Useless
Select Distinct gled.Name LedgerName From
PER_USERS users
Inner Join PER_USER_ROLES roles
    Inner Join PER_ROLES_DN_VL rolesdetail
        Inner Join FUN_USER_ROLE_DATA_ASGNMNTS accdata
            Inner Join GL_LEDGERS gled
            ON accdata.LEDGER_ID = gled.Ledger_Id and gled.Name not like '%_USD' 
        On rolesdetail.Role_Common_Name = accdata.ROLE_NAME and accdata.ACTIVE_FLAG = 'Y' 
    ON rolesdetail.Role_ID = roles.Role_Id 
ON users.USER_ID = roles.User_ID

Where accdata.USER_GUID = users.USER_GUID
and rolesdetail.ROLE_COMMON_NAME like 'ORA_GL_FINANCIAL_ANALYST_JOB'
and users.UserName = fnd_global.USER_Name 

-- Financial Analyst Role With Data Access Id -- Need to be connected Ledger If you want 
Select Distinct gled.DEFAULT_LEDGER_ID Data_Access_Name_Ledger 
From PER_USERS users
Inner Join PER_USER_ROLES roles
    Inner Join PER_ROLES_DN_VL rolesdetail
        Inner Join FUN_USER_ROLE_DATA_ASGNMNTS accdata
            Inner Join GL_ACCESS_SETS gled
            ON accdata.ACCESS_SET_ID = gled.ACCESS_SET_ID and gled.Name not like '%_USD' 
        On rolesdetail.Role_Common_Name = accdata.ROLE_NAME and accdata.ACTIVE_FLAG = 'Y' 
    ON rolesdetail.Role_ID = roles.Role_Id 
ON users.USER_ID = roles.User_ID

Where accdata.USER_GUID = users.USER_GUID
and rolesdetail.ROLE_COMMON_NAME like 'ORA_GL_FINANCIAL_ANALYST_JOB'
and users.UserName = fnd_global.USER_Name


-- Asset Accountant with BOOK_ID 
Select Distinct books.BOOK_TYPE_CODE From PER_USERS users
Inner Join PER_USER_ROLES roles
    Inner Join PER_ROLES_DN_VL rolesdetail
       Inner Join FUN_USER_ROLE_DATA_ASGNMNTS accdata
            Inner Join FA_BOOK_CONTROLS books
            ON books.Book_Control_Id = accdata.Book_Id
        On rolesdetail.Role_Common_Name = accdata.ROLE_NAME  and accdata.ACTIVE_FLAG = 'Y' and accdata.BOOK_ID is not null
    ON rolesdetail.Role_ID = roles.Role_Id 
ON users.USER_ID = roles.User_ID

Where accdata.USER_GUID = users.USER_GUID
and rolesdetail.ROLE_COMMON_NAME = 'ORA_FA_ASSET_ACCOUNTANT_JOB'
and users.UserName = fnd_global.USER_Name


-- Data Access General Accountant with Ledger  
Select gled.Name From PER_USERS users
Inner Join PER_USER_ROLES roles
    Inner Join PER_ROLES_DN_VL rolesdetail
        Inner Join FUN_USER_ROLE_DATA_ASGNMNTS accdata
            Inner Join GL_ACCESS_SETS gledaccess
                Inner Join GL_LEDGERS gled
                ON gledaccess.DEFAULT_LEDGER_ID = gled.Ledger_Id and gled.Name not like '%_USD' 
            ON accdata.ACCESS_SET_ID = gledaccess.ACCESS_SET_ID -- and gled.Name not like '%_USD' 
        On rolesdetail.Role_Common_Name = accdata.ROLE_NAME and accdata.ACTIVE_FLAG = 'Y' 
    ON rolesdetail.Role_ID = roles.Role_Id 
ON users.USER_ID = roles.User_ID

Where accdata.USER_GUID = users.USER_GUID
and rolesdetail.ROLE_COMMON_NAME like 'ORA_GL_GENERAL_ACCOUNTANT_JOB'
and users.UserName = fnd_global.USER_Name