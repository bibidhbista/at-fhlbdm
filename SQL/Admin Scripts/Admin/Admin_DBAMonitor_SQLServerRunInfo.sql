

Create Procedure [dbo].[Admin_DBAMonitor_SQLServerRunInfo]



AS



-- SQL Server Services information (SQL Server 2012) (Query 8) (SQL Server Services Info)

SELECT servicename, process_id, startup_type_desc, status_desc, 

last_startup_time, service_account, is_clustered, cluster_nodename, [filename]

FROM sys.dm_server_services WITH (NOLOCK) OPTION (RECOMPILE);



-- Tells you the account being used for the SQL Server Service and the SQL Agent Service

-- Shows the processid, when they were last started, and their current status

-- Shows whether you are running on a failover cluster instance





-- SQL Server NUMA Node information  (Query 9) (SQL Server NUMA Info)

SELECT node_id, node_state_desc, memory_node_id, processor_group, online_scheduler_count, 

       active_worker_count, avg_load_balance, resource_monitor_state

FROM sys.dm_os_nodes WITH (NOLOCK) 

WHERE node_state_desc <> N'ONLINE DAC' OPTION (RECOMPILE);



-- Gives you some useful information about the composition 

-- and relative load on your NUMA nodes





-- Hardware information from SQL Server 2012  (Query 10) (Hardware Info)

-- (Cannot distinguish between HT and multi-core)

SELECT cpu_count AS [Logical CPU Count], scheduler_count, hyperthread_ratio AS [Hyperthread Ratio],

cpu_count/hyperthread_ratio AS [Physical CPU Count], 

physical_memory_kb/1024 AS [Physical Memory (MB)], committed_kb/1024 AS [Committed Memory (MB)],

committed_target_kb/1024 AS [Committed Target Memory (MB)],

max_workers_count AS [Max Workers Count], affinity_type_desc AS [Affinity Type], 

sqlserver_start_time AS [SQL Server Start Time], virtual_machine_type_desc AS [Virtual Machine Type]  

FROM sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);





