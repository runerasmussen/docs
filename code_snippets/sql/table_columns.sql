/*******************************************************************************************
 table_columns.sql

 Retrieves columns and data types of the current SQL database
 Access required: Reader (dbo rights not required!)
 Usage: Modify SELECT, WHERE and ORDER BY sections to filter as required.
 Author: Rune Rasmussen (www.runerasmussen.dk)
 https://github.com/runerasmussen/docs/blob/master/code_snippets/sql/table_columns.sql
********************************************************************************************/

SELECT
  SCH.name AS SchemaName,
  TAB.name AS TableName,
  --, TAB.object_id AS ObjectID
  COL.name AS ColumnName,
  TYP.name AS DataTypeName,
  TYP.max_length AS MaxLength,
  COL.is_nullable AS IsNullable
FROM
  sys.columns COL
INNER JOIN
  sys.tables TAB ON COL.object_id = TAB.object_id
INNER JOIN
  sys.types TYP ON TYP.user_type_id = COL.user_type_id
LEFT OUTER JOIN
  sys.schemas SCH ON TAB.schema_id = SCH.schema_id
WHERE
  TAB.type = 'U' AND TAB.is_ms_shipped = 0x0
  --AND SCH.Name IN ('<SCHEMANAME>')      /* Filter by Schema names */
  --AND TAB.name IN ('<TABLENAME>')       /* Filter by Table names */
  --AND TYP.name IN ('<DATATYPENAME>')  /* Filter by Data Types */
ORDER BY
	1,2