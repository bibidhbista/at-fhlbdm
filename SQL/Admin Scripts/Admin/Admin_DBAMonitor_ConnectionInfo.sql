

Create Procedure [dbo].[Admin_DBAMonitor_ConnectionInfo]



as



--  Get logins that are connected and how many sessions they have (Query 34) (Connection Counts)

SELECT login_name, [program_name], COUNT(session_id) AS [session_count] 

FROM sys.dm_exec_sessions WITH (NOLOCK)

GROUP BY login_name, [program_name]

ORDER BY COUNT(session_id) DESC OPTION (RECOMPILE);



-- This can help characterize your workload and

-- determine whether you are seeing a normal level of activity





-- Get a count of SQL connections by IP address (Query 35) (Connection Counts by IP Address)

SELECT ec.client_net_address, es.[program_name], es.[host_name], es.login_name, 

COUNT(ec.session_id) AS [connection count] 

FROM sys.dm_exec_sessions AS es WITH (NOLOCK) 

INNER JOIN sys.dm_exec_connections AS ec WITH (NOLOCK) 

ON es.session_id = ec.session_id 

GROUP BY ec.client_net_address, es.[program_name], es.[host_name], es.login_name  

ORDER BY ec.client_net_address, es.[program_name] OPTION (RECOMPILE);



-- This helps you figure where your database load is coming from

-- and verifies connectivity from other machines





-- Get Average Task Counts (run multiple times)  (Query 36) (Avg Task Counts)

SELECT AVG(current_tasks_count) AS [Avg Task Count], 

AVG(runnable_tasks_count) AS [Avg Runnable Task Count],

AVG(pending_disk_io_count) AS [Avg Pending DiskIO Count]

FROM sys.dm_os_schedulers WITH (NOLOCK)

WHERE scheduler_id < 255 OPTION (RECOMPILE);



-- Sustained values above 10 suggest further investigation in that area

-- High Avg Task Counts are often caused by blocking/deadlocking or other resource contention



-- Sustained values above 1 suggest further investigation in that area

-- High Avg Runnable Task Counts are a good sign of CPU pressure

-- High Avg Pending DiskIO Counts are a sign of disk pressure







