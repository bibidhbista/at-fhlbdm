



CREATE PROCEDURE [dbo].[ServerPerfMon_i]     



AS    



DECLARE @PerfCounters TABLE

    (

	  ServerNm VARCHAR(50),

      Counter VARCHAR(256) ,

	  Instance VARCHAR(256) ,

      CounterType INT ,

      FirstValue DECIMAL(38, 2) ,

      FirstDateTime DATETIME ,

      SecondValue DECIMAL(38, 2) ,

      SecondDateTime DATETIME ,

      ValueDiff AS ( SecondValue - FirstValue ) ,

      TimeDiff AS ( DATEDIFF(SS, FirstDateTime, SecondDateTime) ) ,

      CounterValue DECIMAL(38, 2)

    );



INSERT INTO @PerfCounters

	( 

		ServerNm,

		Counter ,

		Instance ,

		CounterType ,

		FirstValue ,

		FirstDateTime

    )

SELECT	@@SERVERNAME,

	RTRIM(counter_name),

	RTRIM(instance_name),

	cntr_type ,

	cntr_value ,

	GETDATE()

FROM sys.dm_os_performance_counters

WHERE counter_name IN ( 

	 'Average Wait Time (ms)'

	,'Average Wait Time Base' 

	,'Buffer Cache Hit Ratio'  

	,'Buffer Cache Hit Ratio Base' 

	,'Lock waits'                                                                                                           

	,'Page reads/sec'        

	,'Page writes/sec'      

	,'Page life expectancy'

	,'Total Server Memory (KB)'

	,'Target Server Memory (KB)'   

	,'Batch Requests/sec'

	,'SQL Compilations/sec'

	,'Memory Grants Pending' 

	) AND 

	CASE WHEN counter_name NOT IN ('Average Wait Time (ms)', 'Average Wait Time Base') THEN 1 ELSE

		CASE WHEN instance_name = '_Total' THEN 1 ELSE 0 END END = 1 AND

	CASE WHEN counter_name <> 'Page life expectancy' THEN 1 ELSE

		CASE WHEN instance_name = '' THEN 1 ELSE 0 END END = 1 AND

	CASE WHEN counter_name <> 'Lock waits' THEN 1 ELSE

		CASE WHEN instance_name IN ('Average wait time (ms)', 'Waits started per second') THEN 1 ELSE 0 END END = 1 

ORDER BY counter_name;



WAITFOR DELAY '00:00:10';



UPDATE  @PerfCounters

SET     SecondValue = cntr_value,

        SecondDateTime = GETDATE()

FROM    sys.dm_os_performance_counters

WHERE   Counter = RTRIM(counter_name)

		AND Instance = RTRIM(instance_name)

        AND counter_name IN ( 

			 'Average Wait Time (ms)'

			,'Average Wait Time Base' 

			,'Buffer Cache Hit Ratio'  

			,'Buffer Cache Hit Ratio Base' 

			,'Lock waits'                                                                                                           

			,'Page reads/sec'        

			,'Page writes/sec'      

			,'Page life expectancy'  

			,'Total Server Memory (KB)'

			,'Target Server Memory (KB)' 

			,'Batch Requests/sec'

			,'SQL Compilations/sec'

			,'Memory Grants Pending' 

) AND 

	CASE WHEN counter_name NOT IN ('Average Wait Time (ms)', 'Average Wait Time Base') THEN 1 ELSE

		CASE WHEN instance_name = '_Total' THEN 1 ELSE 0 END END = 1 AND

	CASE WHEN counter_name <> 'Page life expectancy' THEN 1 ELSE

		CASE WHEN instance_name = '' THEN 1 ELSE 0 END END = 1 AND

	CASE WHEN counter_name <> 'Lock waits' THEN 1 ELSE

		CASE WHEN instance_name IN ('Average wait time (ms)', 'Waits started per second') THEN 1 ELSE 0 END END = 1 







UPDATE  @PerfCounters

SET     CounterValue = SecondValue

WHERE   CounterType IN (65792);					



UPDATE  @PerfCounters

SET     CounterValue = ValueDiff / TimeDiff

WHERE   CounterType IN (272696576);



WITH BaseCounters (Counter, SecondValue) AS (

	SELECT CASE WHEN Counter = 'Buffer Cache Hit Ratio Base' THEN REPLACE(Counter, 'Base', '') END As Counter, SecondValue 

	FROM @PerfCounters WHERE CounterType = 1073939712 AND Counter = 'Buffer Cache Hit Ratio Base' 

)

UPDATE p

SET    p.CounterValue = (p.SecondValue * 100) / COALESCE(NULLIF(b.SecondValue, 0), 1)

FROM @PerfCounters p 

INNER JOIN BaseCounters b ON b.Counter = p.Counter

WHERE p.CounterType IN (537003264);



WITH BaseCounters (Counter, ValueDiff) AS (

	SELECT CASE WHEN Counter = 'Average Wait Time Base' THEN REPLACE(Counter, 'Base', '(ms)') END As Counter, ValueDiff 

	FROM @PerfCounters WHERE CounterType = 1073939712 AND  Counter = 'Average Wait Time Base'

)

UPDATE p

SET    p.CounterValue = p.ValueDiff / COALESCE(NULLIF(b.ValueDiff, 0), 1) / p.TimeDiff

FROM @PerfCounters p 

INNER JOIN BaseCounters b ON b.Counter = p.Counter

WHERE p.CounterType IN (1073874176);

-- (current_value � snapshot) / (current_base_counter_value � snapshot_base_counter_value) / snapshot_length_sec.





INSERT INTO ServerPerfMon

        ( 

			DateRun,

			ServerNm,

			Counter,

			Instance,

			Value			

        )

        SELECT  

				SecondDateTime,

				ServerNm,

				Counter,

				Instance,

                CounterValue   



        FROM    @PerfCounters

		WHERE CounterType NOT IN (1073939712)









