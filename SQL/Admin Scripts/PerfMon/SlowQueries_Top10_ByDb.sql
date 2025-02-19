CREATE PROCEDURE [dbo].[SlowQueries_Top10_ByDb]     

	@Db VARCHAR(50) = NULL,

	@Start datetime2 = NULL

	

AS    



IF @Start IS NULL

BEGIN

	SELECT @Start = dateadd(day,-1, cast(getdate() as date))

	

END



DECLARE @Stop datetime2

SELECT @Stop = cast(getdate() as date)



SELECT database_name, [object_name], CONVERT(DECIMAL(8,2), SPTime) AS SPTime, SPCount, CONVERT(DECIMAL(8,2), AvgSpTime) AS AvgSpTime, CONVERT(DECIMAL(8,2), MaxTime) AS MaxTime, 

	CASE WHEN SPCount = 1 THEN CONVERT(DECIMAL(8,2), SPTime) ELSE CONVERT(DECIMAL(8,2), ((SPTime-MaxTime)/(SPCount-1))) END AS AvgSpTime2

	FROM (

		SELECT ROW_NUMBER() OVER (PARTITION BY database_name ORDER BY database_name ASC, SUM(duration) DESC) rn, database_name, [object_name],

		SUM(duration) AS SPTime, COUNT(*) AS SPCount, SUM(duration)/COUNT(*) AS AvgSpTime, MAX(duration) AS MaxTime

		FROM SlowQueries

		WHERE [timestamp] >= @Start AND [timestamp] < @Stop AND

		CASE WHEN @DB IS NULL THEN 1 ELSE

			CASE WHEN @DB = database_name THEN 1 ELSE 0 END END = 1

	GROUP BY [object_name], database_name

) rn

WHERE rn.rn <= 10 

ORDER BY database_name, SPTime DESC





