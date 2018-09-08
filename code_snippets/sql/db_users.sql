/*******************************************************************************************
	db_users.sql

	Retrieves Users per database and their associated permission roles
	Access required: Reader per DB
	Author: Rune Rasmussen (www.runerasmussen.dk)
	https://github.com/runerasmussen/docs/blob/master/code_snippets/sql/db_users.sql
********************************************************************************************/

DECLARE @DB_USers TABLE
(DBName sysname, UserName sysname, LoginType sysname, AssociatedRole varchar(max),CreateDate datetime,ModifyDate datetime)
 
INSERT @DB_USers
EXEC sp_MSforeachdb
 
'
USE [?]
SELECT ''?'' AS DBName,
case prin.name when ''dbo'' then prin.name + '' (''+ (select SUSER_SNAME(owner_sid) from master.sys.databases where name =''?'') + '')'' else prin.name end AS UserName,
prin.type_desc AS LoginType,
isnull(USER_NAME(mem.role_principal_id),'''') AS AssociatedRole ,create_date,modify_date
FROM sys.database_principals prin
LEFT OUTER JOIN sys.database_role_members mem ON prin.principal_id=mem.member_principal_id
WHERE prin.sid IS NOT NULL and prin.sid NOT IN (0x00) and
prin.is_fixed_role <> 1 AND prin.name NOT LIKE ''##%'''

SELECT
	DBName, UserName, LoginType,
	STUFF((
		SELECT ',' + CONVERT(VARCHAR(500),associatedrole)
		FROM @DB_USers user2
		WHERE user1.DBName=user2.DBName AND user1.UserName=user2.UserName
		FOR XML PATH('')
	),1,1,'') AS [PermissionRoles],
	CreateDate, ModifyDate
FROM
	@DB_USers user1
--WHERE
--	dbname IN ('ATS')	/* Filter by DB name */
GROUP BY
	dbname, username, logintype, CreateDate, ModifyDate
ORDER BY
	DBName, username
