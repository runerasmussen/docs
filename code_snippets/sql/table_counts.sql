/*******************************************************************************************
 table_counts.sql

 Retrieves row counts and storage space used per SQL table
 Access required: Reader (dbo rights not required!)
 Usage: Modify SELECT, WHERE and ORDER BY sections to filter as required.
 Author: Rune Rasmussen (www.runerasmussen.dk)
 https://github.com/runerasmussen/docs/blob/master/code_snippets/sql/table_counts.sql
********************************************************************************************/

SELECT 
  s.Name AS SchemaName,
  t.NAME AS TableName,
  p.rows AS RowCounts,
  SUM(a.total_pages) * 8 / 1024 AS TotalSpaceMB, 
  SUM(a.used_pages) * 8 / 1024 AS UsedSpaceMB, 
  (SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024 AS UnusedSpaceMB
FROM 
  sys.tables t
INNER JOIN      
  sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
  sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
  sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
  sys.schemas s ON t.schema_id = s.schema_id
WHERE 
  t.type = 'U' AND t.is_ms_shipped = 0x0
  --AND t.name IN ('myTable')  /* Filter by Table names */
  --AND s.Name IN ('dbo')      /* Filter by Schema names */
  --AND p.rows = 0             /* Filter by Row counts in per Table */
GROUP BY 
  s.Name, t.Name, p.Rows
ORDER BY
  1,2
  --,p.rows DESC               /* Order by Table Row counts */