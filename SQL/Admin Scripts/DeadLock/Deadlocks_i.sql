CREATE PROCEDURE [dbo].[Deadlocks_i]



AS



DECLARE @MaxRowNum AS INT

SELECT @MaxRowNum = ISNULL(MAX(RowNum), 0) FROM Deadlocks



--Drop/Create temp table to store xml, faster to shred from table that file   

IF OBJECT_ID('tempdb..#xmlResults') IS NOT NULL

DROP TABLE #xmlResults;



CREATE TABLE #xmlResults (

	RowNum INT NOT NULL PRIMARY KEY CLUSTERED IDENTITY(1,1),

	xXML XML NOT NULL

)



--Cursor to loop through files that haven't been imported and aren't the current active file.

DECLARE fileCursor CURSOR READ_ONLY FOR 

	SELECT [FileName] FROM EventFiles WHERE EventName = 'Deadlocks' AND Imported = 0 AND DateRun < CAST(GETDATE() AS date)



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





-- CREATE TEMP TABLES ---------------------------------------

IF OBJECT_ID('tempdb..#VICTIM') IS NOT NULL

	DROP TABLE #VICTIM;

CREATE TABLE #VICTIM(ProcessId varchar(255))



IF OBJECT_ID('tempdb..#KEY_LOCK') IS NOT NULL

	DROP TABLE #KEY_LOCK;

CREATE TABLE #KEY_LOCK(HObtId bigint,DatabaseName varchar(255),ObjectName varchar(255),IndexName varchar(255),ID varchar(255),OwnerMode varchar(255))



IF OBJECT_ID('tempdb..#PAGE_LOCK') IS NOT NULL

	DROP TABLE #PAGE_LOCK;

CREATE TABLE #PAGE_LOCK(FileId bigint,PageId bigint,DatabaseName varchar(255),SubResource nvarchar(255),ObjectName varchar(255),AssociatedObjectId varchar(255),ID varchar(255),OwnerMode varchar(255))



IF OBJECT_ID('tempdb..#PARTITION_LOCK') IS NOT NULL

	DROP TABLE #PARTITION_LOCK;

CREATE TABLE #PARTITION_LOCK(LockPartition bigint,ObjectId bigint,DatabaseName varchar(255),SubResource nvarchar(255),ObjectName varchar(255),AssociatedObjectId varchar(255),ID varchar(255),OwnerMode varchar(255))



IF OBJECT_ID('tempdb..#OWNER') IS NOT NULL

	DROP TABLE #OWNER;

CREATE TABLE #OWNER(HObtId varchar(255),RequestType varchar(20),Mode varchar(20),ProcessId varchar(255))



IF OBJECT_ID('tempdb..#OWNER2') IS NOT NULL

	DROP TABLE #OWNER2;

CREATE TABLE #OWNER2(Id varchar(255),WaitType varchar(255),nodeId bigint,ProcessId varchar(255),IsOwner varchar(20))



IF OBJECT_ID('tempdb..#PROCESS') IS NOT NULL

	DROP TABLE #PROCESS;

CREATE TABLE #PROCESS(RowNum INT, [timestamp] datetime, ProcessId varchar(255),WaitResource varchar(255),TransactionName varchar(255),LockMode varchar(255),[Status] varchar(255),TranCount int,

						ClientApp varchar(255),HostName varchar(255),LoginName varchar(255),IsolationLevel varchar(255),CurrentDB varchar(255),ProcName varchar(255),

						SQLHandle varchar(255),StackBuffer varchar(MAX),InputBuffer varchar(MAX), Spid INT)





-- GET PROCESS LIST -----------------------------------------

INSERT INTO #PROCESS(RowNum,Timestamp,ProcessId,WaitResource,TransactionName,LockMode,[Status],TranCount,ClientApp,HostName,LoginName,IsolationLevel,CurrentDB,ProcName,SQLHandle,StackBuffer,InputBuffer,Spid)

SELECT	rowNum + @MaxRowNum,

		deadlock.value('(/event/@timestamp)[1]','datetime')As [timestamp],

		deadlock.value('@id','varchar(255)') AS ProcessId,

		deadlock.value('@waitresource','varchar(255)') AS WaitResource,

		deadlock.value('@transactionname','varchar(255)') AS TransactionName,

		deadlock.value('@lockMode','varchar(255)') AS LockMode,

		deadlock.value('@status','varchar(255)') AS [Status],

		deadlock.value('@trancount','int') AS TranCount,

		deadlock.value('@clientapp','varchar(255)') AS ClientApp,

		deadlock.value('@hostname','varchar(255)') AS HostName,

		deadlock.value('@loginname','varchar(255)') AS LoginName,

		deadlock.value('@isolationlevel','varchar(255)') AS IsolationLevel,

		DB_NAME(deadlock.value('@currentdb','int')) AS CurrentDB,
		deadlock.value('(executionStack/frame/@procname)[1]','varchar(255)') AS ProcName,

		deadlock.value('(executionStack/frame/@sqlhandle)[1]','varchar(255)') AS SQLHandle,

		deadlock.value('(executionStack/frame)[1]','varchar(MAX)') AS StackBuffer,

		deadlock.value('inputbuf[1]','varchar(MAX)') AS InputBuffer,

		deadlock.value('@spid','varchar(255)') AS Spid

FROM (SELECT rowNum, xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/process-list/process') AS ref2(deadlock)

-------------------------------------------------------------



-- GET VICTIMS ----------------------------------------------

INSERT INTO #VICTIM(ProcessId)

SELECT deadlock.value('@id','varchar(255)') AS ProcessId

FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/victim-list/victimProcess') AS ref(deadlock)

-------------------------------------------------------------



IF EXISTS(SELECT 1 FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/exchangeEvent') AS ref(keylock)

		WHERE keylock.value('(@id)[1]','varchar(255)') IS NOT NULL)

BEGIN

	-- GET OWNER/WAITER -----------------------------------------

	INSERT INTO #OWNER2(Id,WaitType,nodeId,ProcessId,IsOwner)

	SELECT	keylock.value('@id','varchar(255)') AS Id,

			keylock.value('@WaitType','varchar(255)') AS WaitType,

			keylock.value('@nodeId','bigint') AS WaitType,

			keylock.value('(owner-list/owner/@id)[1]','varchar(255)') AS ProcessId,

			'TRUE' AS IsOwner

	FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/exchangeEvent') AS ref(keylock)

			



		UNION ALL



	SELECT	keylock.value('@id','varchar(255)') AS Id,

			keylock.value('@WaitType','varchar(255)') AS WaitType,

			keylock.value('@nodeId','bigint') AS WaitType,

			keylock.value('(waiter-list/waiter/@id)[1]','varchar(255)') AS ProcessId,

			'TRUE' AS IsOwner

	FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/exchangeEvent') AS ref(keylock)

			



	-------------------------------------------------------------

END

ELSE IF EXISTS(

	SELECT 1 FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/keylock') AS ref(keylock)

		WHERE keylock.value('(@hobtid)[1]','bigint') IS NOT NULL

)

BEGIN

	-- GET LOCK LIST --------------------------------------------

	INSERT INTO #KEY_LOCK(HObtId,DatabaseName,ObjectName,IndexName,ID,OwnerMode)

	SELECT	deadlock.value('@hobtid','bigint') AS HObtId,

			DB_NAME(deadlock.value('@dbid','int')) AS DatabaseName,

			deadlock.value('@objectname','varchar(255)') AS ObjectName,

			deadlock.value('@indexname','varchar(255)') AS IndexName,

			deadlock.value('@id','varchar(255)') AS ID,

			deadlock.value('@mode','varchar(255)') AS OwnerMode

	FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/keylock') AS ref(deadlock)

	

	-------------------------------------------------------------



	-- GET OWNER/WAITER -----------------------------------------

	INSERT INTO #OWNER(HObtId,ProcessId,Mode,RequestType)

	SELECT	keylock.value('@hobtid','bigint') AS HObtId,

			keylock.value('(owner-list/owner/@id)[1]','varchar(255)') AS id,

			keylock.value('(owner-list/owner/@mode)[1]','varchar(255)') AS Mode,

			keylock.value('(owner-list/owner/@requestType)[1]','varchar(255)') AS RequestType

	FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/keylock') AS ref(keylock)



		UNION ALL



	SELECT	keylock.value('@hobtid','bigint') AS HObtId,

			keylock.value('(waiter-list/waiter/@id)[1]','varchar(255)') AS id,

			keylock.value('(waiter-list/waiter/@mode)[1]','varchar(255)') AS Mode,

			keylock.value('(waiter-list/waiter/@requestType)[1]','varchar(255)') AS RequestType

	FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/keylock') AS ref(keylock)

	-------------------------------------------------------------

END

ELSE IF EXISTS(

	SELECT 1 FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/pagelock') AS ref(keylock)

		WHERE keylock.value('(@fileid)[1]','bigint') IS NOT NULL)

BEGIN

	-- GET LOCK LIST --------------------------------------------

	INSERT INTO #PAGE_LOCK(FileId,PageId,DatabaseName,SubResource,ObjectName,AssociatedObjectId,ID,OwnerMode)

	SELECT	deadlock.value('@fileid','bigint') AS FileId,

			deadlock.value('@pageid','bigint') AS PageId,

			DB_NAME(deadlock.value('@dbid','int')) AS DatabaseName,

			deadlock.value('@subresource','nvarchar(255)') AS SubResource,

			deadlock.value('@objectname','varchar(255)') AS ObjectName,

			deadlock.value('@associatedObjectId','varchar(255)') AS AssociatedObjectId,

			deadlock.value('@id','varchar(255)') AS ID,

			deadlock.value('@mode','varchar(255)') AS OwnerMode

	FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/pagelock') AS ref(deadlock)

	-------------------------------------------------------------



	-- GET OWNER/WAITER -----------------------------------------

	INSERT INTO #OWNER(HObtId,ProcessId,Mode,RequestType)

	SELECT	keylock.value('@id','varchar(255)') AS HObtId,

			keylock.value('(owner-list/owner/@id)[1]','varchar(255)') AS id,

			keylock.value('(owner-list/owner/@mode)[1]','varchar(255)') AS Mode,

			keylock.value('(owner-list/owner/@requestType)[1]','varchar(255)') AS RequestType

	FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/pagelock') AS ref(keylock)

			

		UNION ALL



	SELECT	keylock.value('@id','varchar(255)') AS HObtId,

			keylock.value('(waiter-list/waiter/@id)[1]','varchar(255)') AS id,

			keylock.value('(waiter-list/waiter/@mode)[1]','varchar(255)') AS Mode,

			keylock.value('(waiter-list/waiter/@requestType)[1]','varchar(255)') AS RequestType

	FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/pagelock') AS ref(keylock)

	-------------------------------------------------------------

END

ELSE IF EXISTS(

	SELECT 1 FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/objectlock') AS ref(keylock)

		WHERE keylock.value('(@lockPartition)[1]','bigint') IS NOT NULL)

BEGIN

	-- GET LOCK LIST --------------------------------------------

	INSERT INTO #PARTITION_LOCK(LockPartition,ObjectId,DatabaseName,SubResource,ObjectName,AssociatedObjectId,ID,OwnerMode)

	SELECT	deadlock.value('@lockPartition','bigint') AS FileId,

			deadlock.value('@objid','bigint') AS PageId,

			DB_NAME(deadlock.value('@dbid','int')) AS DatabaseName,

			deadlock.value('@subresource','nvarchar(255)') AS SubResource,

			deadlock.value('@objectname','varchar(255)') AS ObjectName,

			deadlock.value('@associatedObjectId','varchar(255)') AS AssociatedObjectId,

			deadlock.value('@id','varchar(255)') AS ID,

			deadlock.value('@mode','varchar(255)') AS OwnerMode

	FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/objectlock') AS ref(deadlock)

	-------------------------------------------------------------



	-- GET OWNER/WAITER -----------------------------------------

	INSERT INTO #OWNER(HObtId,ProcessId,Mode,RequestType)

	SELECT	keylock.value('@id','varchar(255)') AS HObtId,

			keylock.value('(owner-list/owner/@id)[1]','varchar(255)') AS id,

			keylock.value('(owner-list/owner/@mode)[1]','varchar(255)') AS Mode,

			keylock.value('(owner-list/owner/@requestType)[1]','varchar(255)') AS RequestType

	FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/objectlock') AS ref(keylock)

			

		UNION ALL



	SELECT	keylock.value('@id','varchar(255)') AS HObtId,

			keylock.value('(waiter-list/waiter/@id)[1]','varchar(255)') AS id,

			keylock.value('(waiter-list/waiter/@mode)[1]','varchar(255)') AS Mode,

			keylock.value('(waiter-list/waiter/@requestType)[1]','varchar(255)') AS RequestType

	FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event/data/value/deadlock/resource-list/objectlock') AS ref(keylock)

			

	-------------------------------------------------------------

END







IF EXISTS(SELECT * FROM #OWNER2)

BEGIN

	INSERT INTO Deadlocks

	SELECT DISTINCT	

			p.RowNum,

			p.Timestamp,

			'' AS database_name,

			'ExchangeEvent' AS [object_name],

			'' AS IndexName,

			p.Spid,

			p.ProcessId,

			p.ProcName,

			'' AS DeadlockVictim,

			'' AS OwnerMode,

			'' AS RequestMode,

			p.LockMode,

			p.StackBuffer,

			p.InputBuffer,

			p.SQLHandle,

			o.WaitType AS RequestType,

			p.[Status],

			p.TranCount,

			p.IsolationLevel,

			p.CurrentDB,

			p.WaitResource,

			p.ClientApp,

			p.HostName,

			p.LoginName		

	FROM #OWNER2 o

		INNER JOIN #PROCESS p ON p.ProcessId = o.ProcessId

	ORDER BY p.Timestamp, p.ProcessId

END

ELSE IF EXISTS(SELECT * FROM #KEY_LOCK)

BEGIN

	INSERT INTO Deadlocks

	SELECT DISTINCT	

			p.RowNum,

			p.Timestamp,

			l.DatabaseName,

			l.ObjectName,

			l.IndexName,

			p.Spid,

			p.ProcessId,

			p.ProcName,

			CASE WHEN v.ProcessId IS NULL THEN 'False' ELSE 'True' END AS [DeadlockVictim],

			l.OwnerMode,

			o.Mode AS [RequestMode],

			p.LockMode,

			p.StackBuffer,

			p.InputBuffer,

			p.SQLHandle,

			o.RequestType,

			p.[Status],

			p.TranCount,

			p.IsolationLevel,

			p.CurrentDB,

			p.WaitResource,

			p.ClientApp,

			p.HostName,

			p.LoginName

	FROM #KEY_LOCK l

		INNER JOIN #OWNER o ON o.HObtId = l.HObtId

		INNER JOIN #PROCESS p ON p.ProcessId = o.ProcessId

		LEFT JOIN #VICTIM v ON v.ProcessId = o.ProcessId

	ORDER BY p.Timestamp, p.ProcessId

END

ELSE IF EXISTS(SELECT * FROM #PAGE_LOCK)

BEGIN

	INSERT INTO Deadlocks

	SELECT DISTINCT	

			p.RowNum,

			p.Timestamp,

			l.DatabaseName,

			l.ObjectName,

			'File:' + CAST(l.FileId AS VARCHAR(20)) + ' Page:' + CAST(l.PageId AS VARCHAR(20)) AS IndexName,	

			p.Spid,

			p.ProcessId,

			p.ProcName,

			CASE WHEN v.ProcessId IS NULL THEN 'False' ELSE 'True' END AS [DeadlockVictim],

			l.OwnerMode,

			o.Mode AS [RequestMode],

			p.LockMode,

			p.StackBuffer,

			p.InputBuffer,

			p.SQLHandle,

			o.RequestType,

			p.[Status],

			p.TranCount,

			p.IsolationLevel,

			p.CurrentDB,

			p.WaitResource,

			p.ClientApp,

			p.HostName,

			p.LoginName

	FROM #PAGE_LOCK l

		INNER JOIN #OWNER o ON o.HObtId = l.ID

		INNER JOIN #PROCESS p ON p.ProcessId = o.ProcessId

		LEFT JOIN #VICTIM v ON v.ProcessId = o.ProcessId

	ORDER BY  p.Timestamp,p.ProcessId

END

ELSE --IF EXISTS(SELECT * FROM #PARTITION_LOCK)

BEGIN

	INSERT INTO Deadlocks

	SELECT DISTINCT	

			p.RowNum,

			p.Timestamp,

			l.DatabaseName,

			l.ObjectName,

			'LockPartition:' + CAST(l.LockPartition AS VARCHAR(20)) AS IndexName,

			p.Spid,

			p.ProcessId,

			p.ProcName,

			CASE WHEN v.ProcessId IS NULL THEN 'False' ELSE 'True' END AS [DeadlockVictim],

			l.OwnerMode,

			o.Mode AS [RequestMode],

			p.LockMode,

			p.StackBuffer,

			p.InputBuffer,

			p.SQLHandle,

			o.RequestType,

			p.[Status],

			p.TranCount,

			p.IsolationLevel,

			p.CurrentDB,

			p.WaitResource,

			p.ClientApp,

			p.HostName,

			p.LoginName

	FROM #PARTITION_LOCK l

		INNER JOIN #OWNER o ON o.HObtId = l.ID

		INNER JOIN #PROCESS p ON p.ProcessId = o.ProcessId

		LEFT JOIN #VICTIM v ON v.ProcessId = o.ProcessId

	ORDER BY  p.Timestamp,p.ProcessId

END



UPDATE EventFiles SET Imported = 1 WHERE EventName = 'Deadlocks' AND Imported = 0 AND DateRun < CAST(GETDATE() AS date)



