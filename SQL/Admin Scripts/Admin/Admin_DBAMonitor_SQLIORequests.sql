

Create Procedure [dbo].[Admin_DBAMonitor_SQLIORequests]



AS



-- Look for I/O requests taking longer than 15 seconds in the five most recent SQL Server Error Logs (Query 23) (IO Warnings)

CREATE TABLE #IOWarningResults(LogDate datetime, ProcessInfo sysname, LogText nvarchar(1000));



	INSERT INTO #IOWarningResults 

	EXEC xp_readerrorlog 0, 1, N'taking longer than 15 seconds';



	INSERT INTO #IOWarningResults 

	EXEC xp_readerrorlog 1, 1, N'taking longer than 15 seconds';



	INSERT INTO #IOWarningResults 

	EXEC xp_readerrorlog 2, 1, N'taking longer than 15 seconds';



	INSERT INTO #IOWarningResults 

	EXEC xp_readerrorlog 3, 1, N'taking longer than 15 seconds';



	INSERT INTO #IOWarningResults 

	EXEC xp_readerrorlog 4, 1, N'taking longer than 15 seconds';



SELECT LogDate, ProcessInfo, LogText

FROM #IOWarningResults

ORDER BY LogDate DESC;



DROP TABLE #IOWarningResults; 

