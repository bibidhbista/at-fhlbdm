CREATE PROCEDURE DiskSpace_s

	@Drive CHAR(1) = NULL,

	@Start DATE = NULL,

	@End   DATE = NULL

AS



WITH t2 AS (

	SELECT ROW_NUMBER() OVER (PARTITION BY Drive ORDER BY DateRun ASC) AS Id,

	*

	FROM DiskSize

	WHERE

		CASE WHEN @Drive IS NULL THEN 1 ELSE

			CASE WHEN Drive = @Drive THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @Start IS NULL THEN 1 ELSE

			CASE WHEN DateRun >= @Start THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @End IS NULL THEN 1 ELSE

			CASE WHEN DateRun < @End THEN 1 ELSE 0 END END = 1

)

SELECT CAST(t1.DateRun AS DATE) AS DateRun, t1.Drive, t1.FreeSpace, t1.TotalSize, t1.FreeSpace - t2.FreeSpace AS Change, t1.VolumeNm 

FROM (

	SELECT ROW_NUMBER() OVER (PARTITION BY Drive ORDER BY DateRun ASC) AS Id,

	*

	FROM DiskSize

	WHERE

		CASE WHEN @Drive IS NULL THEN 1 ELSE

			CASE WHEN Drive = @Drive THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @Start IS NULL THEN 1 ELSE

			CASE WHEN DateRun >= @Start THEN 1 ELSE 0 END END = 1 AND

		CASE WHEN @End IS NULL THEN 1 ELSE

			CASE WHEN DateRun < @End THEN 1 ELSE 0 END END = 1

) t1

LEFT JOIN t2 ON t1.ID = t2.Id + 1 AND t1.Drive = t2.Drive

ORDER BY DRive, DateRun
