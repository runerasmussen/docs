/*******************************************************************************************
 databases_files.sql
 Retrieves size of each file in alle file groups for all databases on the server.
 Access required: TBD
 Usage: TBD
 Author: Rune Rasmussen (www.runerasmussen.dk)
 https://github.com/runerasmussen/docs/blob/master/code_snippets/sql/databases_files.sql
********************************************************************************************/

CREATE TABLE ##temp
(
    DatabaseName sysname,
    LogicalName sysname,
    FilePath nvarchar(500),
    FileSizeMb decimal (18,2),
    FreeSpaceMb decimal (18,2)
)   
EXEC sp_msforeachdb '
Use [?];
Insert Into ##temp (DatabaseName, LogicalName, FilePath, FileSizeMb, FreeSpaceMb)
    Select DB_NAME() AS [DatabaseName], Name,  physical_name,
    Cast(Cast(Round(cast(size as decimal) * 8.0/1024.0,2) as decimal(18,2)) as nvarchar) Size,
    Cast(Cast(Round(cast(size as decimal) * 8.0/1024.0,2) as decimal(18,2)) -
        Cast(FILEPROPERTY(name, ''SpaceUsed'') * 8.0/1024.0 as decimal(18,2)) as nvarchar) As FreeSpace
    From sys.database_files
'
SELECT * FROM ##temp ORDER BY 3
DROP TABLE ##temp
