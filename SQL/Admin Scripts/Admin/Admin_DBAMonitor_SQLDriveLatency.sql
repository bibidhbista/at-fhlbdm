

Create Procedure [dbo].[Admin_DBAMonitor_SQLDriveLatency]



AS



-- Drive level latency information (Query 24) (Drive Level Latency)

-- Based on code from Jimmy May

SELECT [Drive],

	CASE 

		WHEN num_of_reads = 0 THEN 0 

		ELSE (io_stall_read_ms/num_of_reads) 

	END AS [Read Latency],

	CASE 

		WHEN io_stall_write_ms = 0 THEN 0 

		ELSE (io_stall_write_ms/num_of_writes) 

	END AS [Write Latency],

	CASE 

		WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0 

		ELSE (io_stall/(num_of_reads + num_of_writes)) 

	END AS [Overall Latency],

	CASE 

		WHEN num_of_reads = 0 THEN 0 

		ELSE (num_of_bytes_read/num_of_reads) 

	END AS [Avg Bytes/Read],

	CASE 

		WHEN io_stall_write_ms = 0 THEN 0 

		ELSE (num_of_bytes_written/num_of_writes) 

	END AS [Avg Bytes/Write],

	CASE 

		WHEN (num_of_reads = 0 AND num_of_writes = 0) THEN 0 

		ELSE ((num_of_bytes_read + num_of_bytes_written)/(num_of_reads + num_of_writes)) 

	END AS [Avg Bytes/Transfer]

FROM (SELECT LEFT(UPPER(mf.physical_name), 2) AS Drive, SUM(num_of_reads) AS num_of_reads,

	         SUM(io_stall_read_ms) AS io_stall_read_ms, SUM(num_of_writes) AS num_of_writes,

	         SUM(io_stall_write_ms) AS io_stall_write_ms, SUM(num_of_bytes_read) AS num_of_bytes_read,

	         SUM(num_of_bytes_written) AS num_of_bytes_written, SUM(io_stall) AS io_stall

      FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs

      INNER JOIN sys.master_files AS mf WITH (NOLOCK)

      ON vfs.database_id = mf.database_id AND vfs.file_id = mf.file_id

      GROUP BY LEFT(UPPER(mf.physical_name), 2)) AS tab

ORDER BY [Overall Latency] OPTION (RECOMPILE);



-- Shows you the drive-level latency for reads and writes, in milliseconds

-- Latency above 20-25ms is usually a problem





-- Calculates average stalls per read, per write, and per total input/output for each database file  (Query 25) (IO Stalls by File)

SELECT DB_NAME(fs.database_id) AS [Database Name], CAST(fs.io_stall_read_ms/(1.0 + fs.num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms],

CAST(fs.io_stall_write_ms/(1.0 + fs.num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms],

CAST((fs.io_stall_read_ms + fs.io_stall_write_ms)/(1.0 + fs.num_of_reads + fs.num_of_writes) AS NUMERIC(10,1)) AS [avg_io_stall_ms],

CONVERT(DECIMAL(18,2), mf.size/128.0) AS [File Size (MB)], mf.physical_name, mf.type_desc, fs.io_stall_read_ms, fs.num_of_reads, 

fs.io_stall_write_ms, fs.num_of_writes, fs.io_stall_read_ms + fs.io_stall_write_ms AS [io_stalls], fs.num_of_reads + fs.num_of_writes AS [total_io]

FROM sys.dm_io_virtual_file_stats(null,null) AS fs

INNER JOIN sys.master_files AS mf WITH (NOLOCK)

ON fs.database_id = mf.database_id

AND fs.[file_id] = mf.[file_id]

ORDER BY avg_io_stall_ms DESC OPTION (RECOMPILE);



-- Helps determine which database files on the entire instance have the most I/O bottlenecks

-- This can help you decide whether certain LUNs are overloaded and whether you might

-- want to move some files to a different location or perhaps improve your I/O performance





-- Recovery model, log reuse wait description, log file size, log usage size  (Query 26) (Database Properties)

-- and compatibility level for all databases on instance

SELECT db.[name] AS [Database Name], db.recovery_model_desc AS [Recovery Model], db.state_desc, 

db.log_reuse_wait_desc AS [Log Reuse Wait Description], 

CONVERT(DECIMAL(18,2), ls.cntr_value/1024.0) AS [Log Size (MB)], CONVERT(DECIMAL(18,2), lu.cntr_value/1024.0) AS [Log Used (MB)],

CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS [Log Used %], 

db.[compatibility_level] AS [DB Compatibility Level], 

db.page_verify_option_desc AS [Page Verify Option], db.is_auto_create_stats_on, db.is_auto_update_stats_on,

db.is_auto_update_stats_async_on, db.is_parameterization_forced, 

db.snapshot_isolation_state_desc, db.is_read_committed_snapshot_on,

db.is_auto_close_on, db.is_auto_shrink_on, db.target_recovery_time_in_seconds, db.is_cdc_enabled

FROM sys.databases AS db WITH (NOLOCK)

INNER JOIN sys.dm_os_performance_counters AS lu WITH (NOLOCK)

ON db.name = lu.instance_name

INNER JOIN sys.dm_os_performance_counters AS ls WITH (NOLOCK)

ON db.name = ls.instance_name

WHERE lu.counter_name LIKE N'Log File(s) Used Size (KB)%' 

AND ls.counter_name LIKE N'Log File(s) Size (KB)%'

AND ls.cntr_value > 0 OPTION (RECOMPILE);



-- Things to look at:

-- How many databases are on the instance?

-- What recovery models are they using?

-- What is the log reuse wait description?

-- How full are the transaction logs ?

-- What compatibility level are the databases on? 

-- What is the Page Verify Option? (should be CHECKSUM)

-- Is Auto Update Statistics Asynchronously enabled?

-- Make sure auto_shrink and auto_close are not enabled!









