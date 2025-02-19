

CREATE Procedure [dbo].[Admin_DBAMonitor_SQLIOStatistics]



AS



-- Get I/O utilization by database (Query 30) (IO Usage By Database)

WITH Aggregate_IO_Statistics

AS

(SELECT DB_NAME(database_id) AS [Database Name],

CAST(SUM(num_of_bytes_read + num_of_bytes_written)/1048576 AS DECIMAL(12, 2)) AS io_in_mb

FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS [DM_IO_STATS]

GROUP BY database_id)

SELECT ROW_NUMBER() OVER(ORDER BY io_in_mb DESC) AS [I/O Rank], [Database Name], io_in_mb AS [Total I/O (MB)],

       CAST(io_in_mb/ SUM(io_in_mb) OVER() * 100.0 AS DECIMAL(5,2)) AS [I/O Percent]

FROM Aggregate_IO_Statistics

ORDER BY [I/O Rank] OPTION (RECOMPILE);



-- Helps determine which database is using the most I/O resources on the instance





-- Get total buffer usage by database for current instance  (Query 31) (Total Buffer Usage by Database)

-- This make take some time to run on a busy instance

WITH AggregateBufferPoolUsage

AS

(SELECT DB_NAME(database_id) AS [Database Name],

CAST(COUNT(*) * 8/1024.0 AS DECIMAL (10,2))  AS [CachedSize]

FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)

WHERE database_id <> 32767 -- ResourceDB

GROUP BY DB_NAME(database_id))

SELECT ROW_NUMBER() OVER(ORDER BY CachedSize DESC) AS [Buffer Pool Rank], [Database Name], CachedSize AS [Cached Size (MB)],

       CAST(CachedSize / SUM(CachedSize) OVER() * 100.0 AS DECIMAL(5,2)) AS [Buffer Pool Percent]

FROM AggregateBufferPoolUsage

ORDER BY [Buffer Pool Rank] OPTION (RECOMPILE);



-- Tells you how much memory (in the buffer pool) 

-- is being used by each database on the instance





-- Clear Wait Stats with this command

-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);



-- Isolate top waits for server instance since last restart or wait statistics clear  (Query 32) (Top Waits)

WITH [Waits] 

AS (SELECT wait_type, wait_time_ms/ 1000.0 AS [WaitS],

          (wait_time_ms - signal_wait_time_ms) / 1000.0 AS [ResourceS],

           signal_wait_time_ms / 1000.0 AS [SignalS],

           waiting_tasks_count AS [WaitCount],

           100.0 *  wait_time_ms / SUM (wait_time_ms) OVER() AS [Percentage],

           ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS [RowNum]

    FROM sys.dm_os_wait_stats WITH (NOLOCK)

    WHERE [wait_type] NOT IN (

        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',

		N'BROKER_TO_FLUSH', N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',

        N'CHKPT', N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',

        N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE',

		N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',

        N'EXECSYNC', N'FSAGENT', N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',

        N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'HADR_LOGCAPTURE_WAIT', 

		N'HADR_NOTIFICATION_DEQUEUE', N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',

        N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', N'ONDEMAND_TASK_QUEUE',

        N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',

        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'REQUEST_FOR_DEADLOCK_SEARCH',

		N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP',

		N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',

        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',

        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP',

		N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES',

		N'WAIT_FOR_RESULTS', N'WAITFOR', N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT',

		N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',

        N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')

    AND waiting_tasks_count > 0)

SELECT

    MAX (W1.wait_type) AS [WaitType],

    CAST (MAX (W1.WaitS) AS DECIMAL (16,2)) AS [Wait_Sec],

    CAST (MAX (W1.ResourceS) AS DECIMAL (16,2)) AS [Resource_Sec],

    CAST (MAX (W1.SignalS) AS DECIMAL (16,2)) AS [Signal_Sec],

    MAX (W1.WaitCount) AS [Wait Count],

    CAST (MAX (W1.Percentage) AS DECIMAL (5,2)) AS [Wait Percentage],

    CAST ((MAX (W1.WaitS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgWait_Sec],

    CAST ((MAX (W1.ResourceS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgRes_Sec],

    CAST ((MAX (W1.SignalS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgSig_Sec]

FROM Waits AS W1

INNER JOIN Waits AS W2

ON W2.RowNum <= W1.RowNum

GROUP BY W1.RowNum

HAVING SUM (W2.Percentage) - MAX (W1.Percentage) < 99 -- percentage threshold

OPTION (RECOMPILE);





-- The SQL Server Wait Type Repository

-- http://blogs.msdn.com/b/psssql/archive/2009/11/03/the-sql-server-wait-type-repository.aspx



-- Wait statistics, or please tell me where it hurts

-- http://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/



-- SQL Server 2005 Performance Tuning using the Waits and Queues

-- http://technet.microsoft.com/en-us/library/cc966413.aspx



-- sys.dm_os_wait_stats (Transact-SQL)

-- http://msdn.microsoft.com/en-us/library/ms179984(v=sql.120).aspx







-- Signal Waits for instance  (Query 33) (Signal Waits)

SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [% Signal (CPU) Waits],

CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [% Resource Waits]

FROM sys.dm_os_wait_stats WITH (NOLOCK)

WHERE wait_type NOT IN (

        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',

		N'BROKER_TO_FLUSH', N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',

        N'CHKPT', N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',

        N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE',

		N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',

        N'EXECSYNC', N'FSAGENT', N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',

        N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'HADR_LOGCAPTURE_WAIT', 

		N'HADR_NOTIFICATION_DEQUEUE', N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',

        N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', N'ONDEMAND_TASK_QUEUE',

        N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',

        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'REQUEST_FOR_DEADLOCK_SEARCH',

		N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP',

		N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',

        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',

        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP',

		N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES',

		N'WAIT_FOR_RESULTS', N'WAITFOR', N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT',

		N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',

        N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT') OPTION (RECOMPILE);



-- Signal Waits above 10-15% is usually a confirming sign of CPU pressure

-- Cumulative wait stats are not as useful on an idle instance that is not under load or performance pressure

-- Resource waits are non-CPU related waits







