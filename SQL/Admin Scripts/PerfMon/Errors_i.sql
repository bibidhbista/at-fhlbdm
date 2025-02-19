CREATE PROCEDURE Errors_i



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

	SELECT [FileName] FROM EventFiles WHERE EventName = 'Errors' AND Imported = 0 AND DateRun < CAST(GETDATE() AS date)



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





INSERT INTO Errors

SELECT	

		n.value('(@timestamp)[1]','datetime') + GETDATE() - GETUTCDATE() AS timestamp,

		n.value('(action[@name="database_name"]/value)[1]','varchar(255)') AS database_name,

		n.value('(data[@name="error_number"]/value)[1]','int') AS error_number,

		n.value('(data[@name="severity"]/value)[1]','int') AS severity,

		n.value('(data[@name="state"]/value)[1]','int') AS state,

		n.value('(data[@name="message"]/value)[1]','varchar(MAX)') AS message,

		n.value('(action[@name="client_app_name"]/value)[1]','varchar(255)') AS client_app_name,

		n.value('(action[@name="client_hostname"]/value)[1]','varchar(255)') AS client_hostname,

		n.value('(action[@name="nt_username"]/value)[1]','varchar(255)') AS nt_username,

		n.value('(action[@name="session_id"]/value)[1]','int') AS session_id,

		n.value('(data[@name="category"]/value)[1]','int') AS category,

		n.value('(data[@name="category"]/text)[1]','varchar(255)') AS category_text,

		n.value('(data[@name="destination"]/value)[1]','varchar(255)') AS destination,

		n.value('(data[@name="destination"]/text)[1]','varchar(255)') AS destination_text,

		n.value('(action[@name="is_system"]/value)[1]','varchar(20)') AS is_system,

		n.value('(action[@name="plan_handle"]/value)[1]','varchar(255)') AS plan_handle

		

FROM (SELECT xXML

		FROM #xmlResults xm) AS tab

			CROSS APPLY xXML.[nodes]('event') AS [q] ([n])





UPDATE EventFiles SET Imported = 1 WHERE EventName = 'Errors' AND Imported = 0 AND DateRun < CAST(GETDATE() AS date)



