

Create Procedure [dbo].[Admin_DBAMonitor_StatMonitor]



AS



-- When were Statistics last updated on all indexes?  (Query 63) (Statistics Update)

SELECT SCHEMA_NAME(o.Schema_ID) + N'.' + o.NAME AS [Object Name], o.type_desc AS [Object Type],

      i.name AS [Index Name], STATS_DATE(i.[object_id], i.index_id) AS [Statistics Date], 

      s.auto_created, s.no_recompute, s.user_created, st.row_count, st.used_page_count

FROM sys.objects AS o WITH (NOLOCK)

INNER JOIN sys.indexes AS i WITH (NOLOCK)

ON o.[object_id] = i.[object_id]

INNER JOIN sys.stats AS s WITH (NOLOCK)

ON i.[object_id] = s.[object_id] 

AND i.index_id = s.stats_id

INNER JOIN sys.dm_db_partition_stats AS st WITH (NOLOCK)

ON o.[object_id] = st.[object_id]

AND i.[index_id] = st.[index_id]

WHERE o.[type] IN ('U', 'V')

AND st.row_count > 0

ORDER BY STATS_DATE(i.[object_id], i.index_id) DESC OPTION (RECOMPILE);  



-- Helps discover possible problems with out-of-date statistics

-- Also gives you an idea which indexes are the most active



-- Look at most frequently modified indexes and statistics (Query 64) (Volatile Indexes)

SELECT o.name AS [Object Name], o.[object_id], o.type_desc, s.name AS [Statistics Name], 

       s.stats_id, s.no_recompute, s.auto_created, 

	   sp.modification_counter, sp.rows, sp.rows_sampled, sp.last_updated

FROM sys.objects AS o WITH (NOLOCK)

INNER JOIN sys.stats AS s WITH (NOLOCK)

ON s.object_id = o.object_id

CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp

WHERE o.type_desc NOT IN (N'SYSTEM_TABLE', N'INTERNAL_TABLE')

AND sp.modification_counter > 0

ORDER BY sp.modification_counter DESC, o.name OPTION (RECOMPILE);

