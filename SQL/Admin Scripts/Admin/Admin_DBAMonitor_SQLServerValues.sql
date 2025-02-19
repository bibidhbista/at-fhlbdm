





Create Procedure [dbo].[Admin_DBAMonitor_SQLServerValues]



AS







-- Get configuration values for instance  (Query 18) (Configuration Values)

SELECT name, value, value_in_use, minimum, maximum, [description], is_dynamic, is_advanced

FROM sys.configurations WITH (NOLOCK)

ORDER BY name OPTION (RECOMPILE);



-- Focus on

-- backup compression default (should be 1 in most cases)

-- cost threshold for parallelism

-- clr enabled (only enable if it is needed)

-- lightweight pooling (should be zero)

-- max degree of parallelism 

-- max server memory (MB) (set to an appropriate value)

-- optimize for ad hoc workloads (should be 1)

-- priority boost (should be zero)





-- Get information about TCP Listener for SQL Server  (Query 19) (TCP Listener States)

SELECT listener_id, ip_address, is_ipv4, port, type_desc, state_desc, start_time

FROM sys.dm_tcp_listener_states WITH (NOLOCK) 

ORDER BY listener_id OPTION (RECOMPILE);



-- Helpful for network and connectivity troubleshooting





