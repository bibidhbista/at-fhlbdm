CREATE PROCEDURE [dbo].[CPU_Usage_i]     



AS    



DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 



INSERT INTO ServerPerfMon (

	DateRun,

	ServerNm, 

	Counter, 

	Instance,

	Value

)

SELECT TOP(1) 

	DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time],

	@@SERVERNAME,

	'CPU Usage',

	'',

	SQLProcessUtilization               

FROM ( 

	  SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 

			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 

			AS [SystemIdle], 

			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 

			'int') 

			AS [SQLProcessUtilization], [timestamp] 

	  FROM ( 

			SELECT [timestamp], CONVERT(xml, record) AS [record] 

			FROM sys.dm_os_ring_buffers 

			WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 

			AND record LIKE '%<SystemHealth>%') AS x 

	  ) AS y 

ORDER BY record_id DESC;

