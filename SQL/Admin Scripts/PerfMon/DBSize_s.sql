CREATE PROCEDURE DBSize_s



@DBName nvarchar(128) = NULL,

@Start DATE = NULL,

@End   DATE = NULL,

@IncludeLogs AS SMALLINT = 1,

@LogicalFileNm sysname = NULL



AS 



WITH t2 AS (

	SELECT ROW_NUMBER() OVER (PARTITION BY DBName, LogicalFileNm ORDER BY DateRun ASC) AS Id,

	*

	FROM DbSize

	WHERE

		CASE WHEN @DBName IS NULL THEN 1 ELSE

			CASE WHEN DBName = @DBName THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @LogicalFileNm IS NULL THEN 1 ELSE

			CASE WHEN LogicalFileNm = @LogicalFileNm THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @Start IS NULL THEN 1 ELSE

			CASE WHEN DateRun >= @Start THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @End IS NULL THEN 1 ELSE

			CASE WHEN DateRun < @End THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @IncludeLogs = 1 THEN 1 ELSE

			CASE WHEN LogicalFileNm NOT LIKE '%Log' THEN 1 ELSE 0 END END = 1

)

SELECT t1.DateRun, t1.ServerNm, t1.DBName, t1.LogicalFileNm, t1.SizeMB, CAST(t1.UsedSpaceMB AS DECIMAL(18,2)) AS UsedSpaceMB, 

	CAST(t1.FreeSpaceMB AS DECIMAL(18,2)) AS FreeSpaceMB, t1.UsedPrct, t1.FreePrct, CAST(t1.IndexSize AS DECIMAL(18,2)) AS IndexSize,

	CAST((t1.UsedSpaceMB - t2.UsedSpaceMB) AS DECIMAL(18,2)) AS UsedMBChange, 

	CAST((t1.UsedPrct - t2.UsedPrct) AS DECIMAL(18,2)) AS UsedPrctChange

FROM (

	SELECT ROW_NUMBER() OVER (PARTITION BY DBName, LogicalFileNm ORDER BY DateRun ASC) AS Id,

	*

	FROM DbSize

	WHERE

		CASE WHEN @DBName IS NULL THEN 1 ELSE

			CASE WHEN DBName = @DBName THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @LogicalFileNm IS NULL THEN 1 ELSE

			CASE WHEN LogicalFileNm = @LogicalFileNm THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @Start IS NULL THEN 1 ELSE

			CASE WHEN DateRun >= @Start THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @End IS NULL THEN 1 ELSE

			CASE WHEN DateRun < @End THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @IncludeLogs = 1 THEN 1 ELSE

			CASE WHEN LogicalFileNm NOT LIKE '%Log' THEN 1 ELSE 0 END END = 1

) t1

LEFT JOIN t2 ON t1.ID = t2.Id + 1 AND t1.DBName = t2.DBName AND t1.LogicalFileNm = t2.LogicalFileNm

ORDER BY t1.DBName, t1.LogicalFileNm, t1.DateRun
