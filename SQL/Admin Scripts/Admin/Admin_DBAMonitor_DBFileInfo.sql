



Create Procedure [dbo].[Admin_DBAMonitor_DBFileInfo]



AS



-- File names and paths for TempDB and all user databases in instance  (Query 21) (Database Filenames and Paths)

SELECT DB_NAME([database_id]) AS [Database Name], 

       [file_id], name, physical_name, type_desc, state_desc,

	   is_percent_growth, growth,

	   CONVERT(bigint, growth/128.0) AS [Growth in MB], 

       CONVERT(bigint, size/128.0) AS [Total Size in MB]

FROM sys.master_files WITH (NOLOCK)

WHERE [database_id] > 4 

AND [database_id] <> 32767

OR [database_id] = 2

ORDER BY DB_NAME([database_id]) OPTION (RECOMPILE);



-- Things to look at:

-- Are data files and log files on different drives?

-- Is everything on the C: drive?

-- Is TempDB on dedicated drives?

-- Is there only one TempDB data file?

-- Are all of the TempDB data files the same size?

-- Are there multiple data files for user databases?

-- Is percent growth enabled for any files (which is bad)?





-- Volume info for all LUNS that have database files on the current instance (SQL Server 2008 R2 SP1 or greater)  (Query 22) (Volume Info)

SELECT DISTINCT vs.volume_mount_point, vs.file_system_type, 

vs.logical_volume_name, CONVERT(DECIMAL(18,2),vs.total_bytes/1073741824.0) AS [Total Size (GB)],

CONVERT(DECIMAL(18,2),vs.available_bytes/1073741824.0) AS [Available Size (GB)],  

CAST(CAST(vs.available_bytes AS FLOAT)/ CAST(vs.total_bytes AS FLOAT) AS DECIMAL(18,2)) * 100 AS [Space Free %] 

FROM sys.master_files AS f WITH (NOLOCK)

CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs OPTION (RECOMPILE);



--Shows you the total and free space on the LUNs where you have database files





