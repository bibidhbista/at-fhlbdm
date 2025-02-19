

CREATE PROCEDURE [dbo].[FileIoStats_s]

	@DBname VARCHAR(50) = NULL,

	@Date Date = NULL,

	@IncludeLogs SMALLINT = 1



AS



IF @Date IS NULL

BEGIN

	SELECT @Date = dateadd(day,-1, cast(getdate() as date))

END;



WITH t2 AS (

	SELECT ROW_NUMBER() OVER (PARTITION BY physical_name ORDER BY DateRun ASC) AS Id,

	*

	FROM FileIoStats WHERE CAST(DateRun AS Date) = @Date AND 

		CASE WHEN @DBName IS NULL THEN 1 ELSE

			CASE WHEN DBname = @DBname THEN 1 ELSE 0 END END = 1 AND 

		CASE WHEN @IncludeLogs = 1 THEN 1 ELSE

			CASE WHEN FileType <> 'Log' THEN 1 ELSE 0 END END = 1

)

SELECT t1.DBname, t1.DateRun, t1.physical_name, 

	CASE WHEN t2.num_of_reads - t1.num_of_reads = 0 OR t2.num_of_reads IS  NULL THEN 0 ELSE t1.readlatency END AS ReadLatency,

	CASE WHEN t2.num_of_writes - t1.num_of_writes = 0 OR t2.num_of_writes IS NULL THEN 0 ELSE t1.writelatency END AS WriteLatency, 

	CASE WHEN (t2.num_of_reads - t1.num_of_reads = 0 AND t2.num_of_writes - t1.num_of_writes = 0) OR t2.num_of_reads IS NULL AND	

		t2.num_of_writes IS NULL THEN 0 ELSE t1.latency  END AS Latency,

	CASE WHEN t2.num_of_reads - t1.num_of_reads = 0 THEN 0 ELSE (t2.num_of_bytes_read - t1.num_of_bytes_read) / (t2.num_of_reads - t1.num_of_reads) END AS AvgBytesPerRead,

	CASE WHEN t2.num_of_writes - t1.num_of_writes = 0 THEN 0 ELSE (t2.num_of_bytes_written - t1.num_of_bytes_written) / (t2.num_of_writes - t1.num_of_writes) END AS AvgBytesPerWrite,

	CASE WHEN t2.num_of_reads - t1.num_of_reads = 0 AND t2.num_of_writes - t1.num_of_writes = 0 THEN 0

		ELSE ((t2.num_of_bytes_read - t1.num_of_bytes_read) + (t2.num_of_bytes_written - t1.num_of_bytes_written)) / 

		((t2.num_of_reads - t1.num_of_reads) + (t2.num_of_writes - t1.num_of_writes)) END AS AvgBytesPerTransfer,

	t2.num_of_reads - t1.num_of_reads AS Reads,

	t2.num_of_bytes_read - t1.num_of_bytes_read AS BytesRead,

	t2.num_of_writes - t1.num_of_writes AS Writes,

	t2.num_of_bytes_written - t1.num_of_bytes_written AS BytesWritten

FROM (

	SELECT ROW_NUMBER() OVER (PARTITION BY physical_name ORDER BY DateRun ASC) AS Id,

	*

	FROM FileIoStats WHERE CAST(DateRun AS Date) = @Date AND 

		CASE WHEN @DBName IS NULL THEN 1 ELSE

			CASE WHEN DBname = @DBname THEN 1 ELSE 0 END END = 1 AND 

		CASE WHEN @IncludeLogs = 1 THEN 1 ELSE

			CASE WHEN FileType <> 'Log' THEN 1 ELSE 0 END END = 1

) t1

LEFT JOIN t2 ON t1.ID + 1 = t2.Id AND t1.physical_name = t2.physical_name

ORDER BY DBName, physical_name DESC, t2.Id





OPTION (RECOMPILE)

