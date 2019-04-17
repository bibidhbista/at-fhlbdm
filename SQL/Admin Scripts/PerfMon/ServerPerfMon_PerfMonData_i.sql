



CREATE PROCEDURE [dbo].[ServerPerfMon_PerfMonData_i]

	

AS



INSERT INTO ServerPerfMon

SELECT d.DateRun, c.MachineName AS ServerNm, c.CounterName AS Counter, c.InstanceName AS Instance, d.CounterValue AS Value

FROM PerfMonCounters c

INNER JOIN PerfMonData d ON d.CounterId = c.CounterId







