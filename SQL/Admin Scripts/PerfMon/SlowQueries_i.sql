CREATE PROCEDURE [dbo].[SlowQueries_i]



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

	SELECT [FileName] FROM EventFiles WHERE EventName = 'SlowQueries' AND Imported = 0 AND DateRun < CAST(GETDATE() AS date)



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





INSERT INTO SlowQueries

SELECT 

	n.value('(@timestamp)[1]','datetime') + GETDATE() - GETUTCDATE() AS timestamp,

	n.value('(action[@name="database_name"]/value)[1]','varchar(255)') AS database_name,

	CASE WHEN CHARINDEX('iBATIS',CONVERT(varchar(100),  n.value ('(/event/data[@name=''statement'']/value)[1]', 'VARCHAR(MAX)'))) = 0 THEN n.value ('(/event/data[@name=''object_name'']/value)[1]', 'VARCHAR(MAX)')

		ELSE SUBSTRING(n.value('(/event/data[@name=''statement'']/value)[1]', 'VARCHAR(MAX)'),34,(CHARINDEX('*/', n.value ('(/event/data[@name=''statement'']/value)[1]', 'VARCHAR(MAX)')) -34)) END AS object_name,

	CONVERT(decimal(10,2),n.value('(data[@name="duration"]/value)[1]','float')/1000000.0) AS duration,

	n.value('(data[@name="row_count"]/value)[1]','bigint') AS row_count,

	CONVERT(decimal(10,2),n.value('(data[@name="cpu_time"]/value)[1]','float')/1000000.0) AS cpu_time,

	n.value('(data[@name="physical_reads"]/value)[1]','bigint') AS physical_reads,

	n.value('(data[@name="logical_reads"]/value)[1]','bigint') AS logical_reads,

	n.value('(data[@name="writes"]/value)[1]','bigint') AS writes,

	n.value('(action[@name="client_app_name"]/value)[1]','varchar(255)') AS client_app_name,

	n.value('(action[@name="client_hostname"]/value)[1]','varchar(255)') AS client_hostname,

	n.value('(action[@name="nt_username"]/value)[1]','varchar(255)') AS nt_username,

	n.value('(data[@name="statement"]/value)[1]','varchar(MAX)') AS statement,

	n.value('(data[@name="output_parameters"]/value)[1]','varchar(MAX)') AS output_parameters,

	n.value('(action[@name="plan_handle"]/value)[1]','varchar(255)') AS plan_handle,

	n.value('(action[@name="session_id"]/value)[1]','int') AS session_id,

	n.value('(@name)[1]','varchar(50)') AS event_name,

	n.value('(data[@name="result"]/value)[1]','bigint') AS result

FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event') AS [q] ([n])

			



UPDATE EventFiles SET Imported = 1 WHERE EventName = 'SlowQueries' AND Imported = 0 AND DateRun < CAST(GETDATE() AS date)

