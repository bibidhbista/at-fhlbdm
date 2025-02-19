CREATE PROCEDURE Blocking_i



AS



--Drop/Create temp table to store xml, faster to shred from table that file   

IF OBJECT_ID('tempdb..#xmlResults') IS NOT NULL

DROP TABLE #xmlResults;



CREATE TABLE #xmlResults (

	RowNum INT NOT NULL PRIMARY KEY CLUSTERED IDENTITY(1,1),

	xXML XML NOT NULL

)



--Cursor to loop through files that haven't been imported and aren't the current active file.

DECLARE fileCursor CURSOR READ_ONLY FOR 

	SELECT [FileName] FROM EventFiles WHERE EventName = 'Blocking' AND Imported = 0 AND DateRun < CAST(GETDATE() AS date)



DECLARE @FileNm VARCHAR(200)



OPEN fileCursor



FETCH NEXT FROM fileCursor INTO @FileNm

WHILE (@@FETCH_STATUS <> -1)

BEGIN

	--Insert xml records, 1 row per event

	INSERT INTO #xmlResults

	SELECT *

	FROM 

	    (SELECT CONVERT (XML, event_data) AS data FROM sys.fn_xe_file_target_read_file

	         (@FileNm, NULL, NULL, NULL)

	    ) entries



	FETCH NEXT FROM fileCursor INTO @FileNm

END

CLOSE fileCursor

DEALLOCATE fileCursor





INSERT INTO Blocking

SELECT 

	tab.xXML.value('(/event/@timestamp)[1]','datetime') + GETDATE() - GETUTCDATE() AS [TimeStamp],

	DB_NAME(blocked.value('@currentdb','int')) AS [dbName],

	CONVERT(decimal(10,2),tab.xXML.value('(/event/data/value)[1]','bigint')/1000000.0) AS [BlockDuration],

	blocked.value('@spid','int') AS SPID,

	tab.xXML.value('(event/data[@name="blocked_process"]/value/blocked-process-report/blocking-process/process/@spid)[1]','int') AS [Blocking_SPID],

	blocked.value('@hostname','varchar(255)') AS HostName,

	blocked.value('@loginname','varchar(255)') AS LoginName,

	blocked.value('(inputbuf)[1]','varchar(MAX)') AS [Buffered_Input],	

	blocked.value('@clientapp','varchar(255)') AS ClientApp,	

	blocked.value('@isolationlevel','varchar(255)') AS IsolationLevel,

	blocked.value('@lockMode','varchar(255)') AS LockMode,

	blocked.value('@id','varchar(255)') AS [ProcessId],

	blocked.value('@status','varchar(255)') AS [Status],	

	blocked.value('@waitresource','varchar(255)') AS WaitResource,

	blocked.value('@waittime','bigint') AS WaitTime,	

	blocked.value('@transactionname','varchar(255)') AS TransactionName,

	blocked.value('@lasttranstarted','varchar(255)') AS LastTranStarted,	

	blocked.value('@lastbatchstarted','datetime') AS LastBatchStarted,

	blocked.value('@lastbatchcompleted','datetime') AS LastBatchCompleted

FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data[@name="blocked_process"]/value/blocked-process-report/blocked-process/process') AS [q] ([blocked])

UNION ALL

SELECT	tab.xXML.value('(/event/@timestamp)[1]','datetime') + GETDATE() - GETUTCDATE() AS [TimeStamp],

		DB_NAME(blocking.value('@currentdb','int')) AS [dbName],

		NULL AS [BlockDuration],

		blocking.value('@spid','int') AS SPID,

		NULL AS [Blocking_SPID],

		blocking.value('@hostname','varchar(255)') AS HostName,

		blocking.value('@loginname','varchar(255)') AS LoginName,

		blocking.value('(inputbuf)[1]','varchar(MAX)') AS [Buffered_Input],

		blocking.value('@clientapp','varchar(255)') AS ClientApp,		

		blocking.value('@isolationlevel','varchar(255)') AS IsolationLevel,

		'' AS LockMode,

		'' AS [ProcessId],

		blocking.value('@status','varchar(255)') AS [Status],		

		blocking.value('@waitresource','varchar(255)') AS WaitResource,

		blocking.value('@waittime','bigint') AS WaitTime,		

		'' AS TransactionName,

		'' AS LastTranStarted,		

		blocking.value('@lastbatchstarted','datetime') AS LastBatchStarted,

		blocking.value('@lastbatchcompleted','datetime') AS LastBatchCompleted

FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data[@name="blocked_process"]/value/blocked-process-report/blocking-process/process') AS [q] ([blocking])

ORDER BY TimeStamp, Blocking_Spid



UPDATE EventFiles SET Imported = 1 WHERE EventName = 'Blocking' AND Imported = 0 AND DateRun < CAST(GETDATE() AS date)

