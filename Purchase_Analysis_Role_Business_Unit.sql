Select
users.Username UserName,
rolesdetail.ROLE_NAME,
horg.Name BusinessUnit

From

PER_USERS users
Inner Join PER_USER_ROLES roles
    Inner Join PER_ROLES_DN_VL rolesdetail
        Inner Join FUN_USER_ROLE_DATA_ASGNMNTS accdata
            Inner Join hr_organization_units horg
            ON horg.Organization_Id = accdata.Org_Id
        On rolesdetail.Role_Common_Name = accdata.ROLE_NAME and accdata.ACTIVE_FLAG = 'Y' 
    ON rolesdetail.Role_ID = roles.Role_Id 
ON users.USER_ID = roles.User_ID

Where accdata.USER_GUID = users.USER_GUID
and rolesdetail.ROLE_COMMON_NAME = 'ORA_PO_PURCHASE_ANALYSIS_ABSTRACT'
and users.UserName = fnd_global.USER_Name 
