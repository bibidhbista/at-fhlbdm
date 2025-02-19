SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF OBJECT_ID('tempdb..#jobstats') IS NOT NULL
DROP TABLE #jobstats

IF OBJECT_ID('tempdb..#jobinfo') IS NOT NULL
DROP TABLE #jobinfo

IF OBJECT_ID('tempdb..#jobsched') IS NOT NULL
DROP TABLE #jobsched

IF OBJECT_ID('tempdb..#jobsteps') IS NOT NULL
DROP TABLE #jobsteps

/* Get maintenance plan steps if we're on 2008 or newer */
CREATE TABLE #jobsteps ([name] NVARCHAR(128), maintenance_plan_xml XML);

IF CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) LIKE '1%'
  INSERT INTO #jobsteps ([name], maintenance_plan_xml)
  SELECT [name],
                CAST(CAST([packagedata] AS VARBINARY(MAX)) AS XML) AS [maintenance_plan_xml]
         FROM [msdb].[dbo].[sysssispackages]
         WHERE [packagetype] = 6;

/*Maintenance plans*/
;
WITH XMLNAMESPACES ('www.microsoft.com/SqlServer/Dts' AS [DTS]),
    [maintenance_plan_steps] AS (
         SELECT [name], [maintenance_plan_xml]
         FROM #jobsteps
    ), 
    [maintenance_plan_table] AS (
        SELECT [mps].[name],
               [c].[value]('(@DTS:ObjectName)', 'NVARCHAR(128)') AS [step_name]
        FROM [maintenance_plan_steps] [mps]
            CROSS APPLY [maintenance_plan_xml].[nodes]('//DTS:Executables/DTS:Executable') [t]([c])
        WHERE [c].[value]('(@DTS:ObjectName)', 'NVARCHAR(128)') NOT LIKE '%{%}%'
    ),
    [mp_steps_pretty] AS (
        SELECT DISTINCT [m1].[name] ,
            STUFF((
                  SELECT N', ' + [m2].[step_name]  
                  FROM  [maintenance_plan_table] AS [m2] 
                  WHERE [m1].[name] = [m2].[name] 
                FOR XML PATH(N'')), 1, 2, N''
              ) AS [maintenance_plan_steps]
        FROM [maintenance_plan_table] AS [m1]
    ),
    [mp_info] AS (
        SELECT [plan_id] ,
                AVG(DATEDIFF(SECOND, [start_time], [end_time])) AS [avg_runtime_seconds] ,
                SUM(CASE [succeeded]
                      WHEN 1 THEN 0
                      ELSE 1
                    END) AS [failures]
        FROM [msdb].[dbo].[sysmaintplan_log]
        GROUP BY
            [plan_id] ,
            [succeeded]
     )
     SELECT
        [p].[name] ,
        [p].[id] ,
        [p].[owner] ,
        [cac].[Subplan_Count] ,
        [mp_info].[avg_runtime_seconds] ,
        [mp_info].[failures],
        [msp].[maintenance_plan_steps]
     FROM
        [msdb].[dbo].[sysmaintplan_plans] [p]
        LEFT JOIN [mp_info]
          ON [mp_info].[plan_id] = [p].[id]
        JOIN [mp_steps_pretty] [msp]
          ON [msp].[name] = [p].[name]
        CROSS APPLY ( 
          SELECT
              COUNT(*) AS [Subplan_Count]
          FROM
              [msdb].[dbo].[sysmaintplan_subplans] [sp]
          WHERE
              [p].[id] = [sp].[plan_id] 
    ) [cac];

/*Agent Jobs*/
SELECT
    [sjh].[job_id] ,
    SUM(CASE WHEN [sjh].[run_status] = 1
                  AND [sjh].[step_id] = 0 THEN 1
             ELSE 0
        END) AS [job_success] ,
    SUM(CASE WHEN [sjh].[run_status] = 3
                  AND [sjh].[step_id] = 0 THEN 1
             ELSE 0
        END) AS [job_cancel] ,
    SUM(CASE WHEN [sjh].[run_status] = 2 THEN 1
             ELSE 0
        END) AS [job_retry] ,
    SUM(CASE WHEN [sjh].[run_status] = 0
                  AND [sjh].[step_id] = 0 THEN 1
             ELSE 0
        END) AS [job_fail] ,
    MAX([cas].[last_failure_date]) AS [last_failure_date] ,
    MAX([sjh].[operator_id_emailed]) AS [operator_id_emailed] ,
    MIN(CASE WHEN [sjh].[run_duration] IS NOT NULL
             THEN STUFF(STUFF(STUFF(RIGHT('00000000'
                                          + CAST([sjh].[run_duration] AS VARCHAR(8)),
                                          8), 3, 0, ':'), 6, 0, ':'), 9, 0,
                        ':')
             ELSE NULL
        END) AS [shortest_duration] ,
    MAX(CASE WHEN [sjh].[run_duration] IS NOT NULL
             THEN STUFF(STUFF(STUFF(RIGHT('00000000'
                                          + CAST([sjh].[run_duration] AS VARCHAR(8)),
                                          8), 3, 0, ':'), 6, 0, ':'), 9, 0,
                        ':')
             ELSE NULL
        END) AS [longest_duration] ,
    MAX([can].[stop_execution_date]) AS [last_run_date] ,
    MAX([can].[next_scheduled_run_date]) [next_run_date]
INTO #jobstats
FROM
    [msdb].[dbo].[sysjobhistory] AS [sjh]
    OUTER APPLY ( SELECT TOP 1
                    [sja].[stop_execution_date] ,
                    [sja].[next_scheduled_run_date]
                  FROM
                    [msdb].[dbo].[sysjobactivity] [sja]
                  WHERE
                    [sja].[job_id] = [sjh].[job_id]
                  ORDER BY
                    [sja].[run_requested_date] DESC ) [can]
    OUTER APPLY ( SELECT TOP 1
                    CAST(CAST([s].[run_date] AS VARCHAR(10)) AS DATETIME) AS [last_failure_date]
                  FROM
                    [msdb].[dbo].[sysjobhistory] AS [s]
                  WHERE
                    [s].[job_id] = [sjh].[job_id]
                    AND [s].[run_status] = 0
                  ORDER BY
                    [sjh].[run_date] DESC ) AS [cas]
GROUP BY
    [sjh].[job_id];

SELECT
    [sj].[job_id] ,
    [sj].[name] ,
    CASE [sj].[enabled]
      WHEN 1 THEN 'Enabled'
      ELSE 'Disabled -- Should I be?'
    END AS [is_enabled] ,
    SUSER_SNAME([sj].[owner_sid]) AS [owner_name] ,
    CASE [sj].[notify_level_eventlog]
      WHEN 0 THEN 'Never'
      WHEN 1 THEN 'When the job succeeds'
      WHEN 2 THEN 'When the job fails'
      WHEN 3 THEN 'When the job completes'
    END AS [log_when] ,
    CASE [sj].[notify_level_email]
      WHEN 0 THEN 'Never'
      WHEN 1 THEN 'When the job succeeds'
      WHEN 2 THEN 'When the job fails'
      WHEN 3 THEN 'When the job completes'
    END AS [email_when] ,
    ISNULL([so].[name], 'No operator') AS [operator_name] ,
    ISNULL([so].[email_address], 'No email address') AS [operator_email_address] ,
    CASE [so].[enabled]
      WHEN 1 THEN 'Enabled'
      ELSE 'Not Enabled'
    END AS [is_operator_enabled]
INTO #jobinfo
FROM
    [msdb].[dbo].[sysjobs] [sj]
    LEFT JOIN [msdb].[dbo].[sysoperators] [so]
    ON [so].[id] = [sj].[notify_email_operator_id];    


;WITH jobsched AS (
SELECT
    [sjs].[job_id] ,
    CASE [ss].[freq_type]
      WHEN 1 THEN 'Once'
      WHEN 4 THEN 'Daily'
      WHEN 8 THEN 'Weekly'
      WHEN 16 THEN 'Monthly'
      WHEN 32 THEN 'Monthly relative'
      WHEN 64 THEN 'When Agent starts'
      WHEN 128 THEN 'When CPUs are idle'
      ELSE NULL
    END AS [frequency] ,
    CASE [ss].[freq_type]
      WHEN 1 THEN 'O'
      WHEN 4
      THEN 'Every ' + CONVERT(VARCHAR(100), [ss].[freq_interval]) + ' day(s)'
      WHEN 8
      THEN 'Every ' + CONVERT(VARCHAR(100), [ss].[freq_recurrence_factor])
           + ' weeks(s) on '
           + CASE WHEN [ss].[freq_interval] & 1 = 1 THEN 'Sunday, '
                  ELSE ''
             END + CASE WHEN [ss].[freq_interval] & 2 = 2 THEN 'Monday, '
                        ELSE ''
                   END
           + CASE WHEN [ss].[freq_interval] & 4 = 4 THEN 'Tuesday, '
                  ELSE ''
             END + CASE WHEN [ss].[freq_interval] & 8 = 8 THEN 'Wednesday, '
                        ELSE ''
                   END
           + CASE WHEN [ss].[freq_interval] & 16 = 16 THEN 'Thursday, '
                  ELSE ''
             END + CASE WHEN [ss].[freq_interval] & 32 = 32 THEN 'Friday, '
                        ELSE ''
                   END
           + CASE WHEN [ss].[freq_interval] & 64 = 64 THEN 'Saturday, '
                  ELSE ''
             END
      WHEN 16
      THEN 'Day ' + CONVERT(VARCHAR(100), [ss].[freq_interval]) + ' of every '
           + CONVERT(VARCHAR(100), [ss].[freq_recurrence_factor])
           + ' month(s)'
      WHEN 32
      THEN 'The ' + CASE [ss].[freq_relative_interval]
                      WHEN 1 THEN 'First'
                      WHEN 2 THEN 'Second'
                      WHEN 4 THEN 'Third'
                      WHEN 8 THEN 'Fourth'
                      WHEN 16 THEN 'Last'
                    END + CASE [ss].[freq_interval]
                            WHEN 1 THEN ' Sunday'
                            WHEN 2 THEN ' Monday'
                            WHEN 3 THEN ' Tuesday'
                            WHEN 4 THEN ' Wednesday'
                            WHEN 5 THEN ' Thursday'
                            WHEN 6 THEN ' Friday'
                            WHEN 7 THEN ' Saturday'
                            WHEN 8 THEN ' Day'
                            WHEN 9 THEN ' Weekday'
                            WHEN 10 THEN ' Weekend Day'
                          END + ' of every '
           + CONVERT(VARCHAR(100), [ss].[freq_recurrence_factor])
           + ' month(s)'
      ELSE NULL
    END AS [schedule],
    CASE [ss].[freq_subday_type]
      WHEN 1
      THEN 'Occurs once at ' + STUFF(STUFF(RIGHT('000000'
                                                 + CONVERT(VARCHAR(8), [ss].[active_start_time]),
                                                 6), 5, 0, ':'), 3, 0, ':')
      WHEN 2
      THEN 'Occurs every ' + CONVERT(VARCHAR(100), [ss].[freq_subday_interval])
           + ' Seconds(s) between ' + STUFF(STUFF(RIGHT('000000'
                                                        + CONVERT(VARCHAR(8), [ss].[active_start_time]),
                                                        6), 5, 0, ':'), 3, 0,
                                            ':') + ' and '
           + STUFF(STUFF(RIGHT('000000'
                               + CONVERT(VARCHAR(8), [ss].[active_end_time]),
                               6), 5, 0, ':'), 3, 0, ':')
      WHEN 4
      THEN 'Occurs every ' + CONVERT(VARCHAR(100), [ss].[freq_subday_interval])
           + ' Minute(s) between ' + STUFF(STUFF(RIGHT('000000'
                                                       + CONVERT(VARCHAR(8), [ss].[active_start_time]),
                                                       6), 5, 0, ':'), 3, 0,
                                           ':') + ' and '
           + STUFF(STUFF(RIGHT('000000'
                               + CONVERT(VARCHAR(8), [ss].[active_end_time]),
                               6), 5, 0, ':'), 3, 0, ':')
      WHEN 8
      THEN 'Occurs every ' + CONVERT(VARCHAR(100), [ss].[freq_subday_interval])
           + ' Hour(s) between ' + STUFF(STUFF(RIGHT('000000'
                                                     + CONVERT(VARCHAR(8), [ss].[active_start_time]),
                                                     6), 5, 0, ':'), 3, 0, ':')
           + ' and ' + STUFF(STUFF(RIGHT('000000'
                                         + CONVERT(VARCHAR(8), [ss].[active_end_time]),
                                         6), 5, 0, ':'), 3, 0, ':')
      ELSE NULL
    END AS [schedule_detail]
FROM
    [msdb].[dbo].[sysjobschedules] AS [sjs]
    INNER JOIN [msdb].[dbo].[sysschedules] AS [ss]
    ON [sjs].[schedule_id] = [ss].[schedule_id]
)
SELECT [jobsched].[job_id] ,
       [jobsched].[frequency] ,
       LEFT([jobsched].[schedule], LEN([jobsched].[schedule]) -1) AS [schedule],
       [jobsched].[schedule_detail]
INTO #jobsched
FROM [jobsched]
 
SELECT
    [j].[name] ,
    [j].[is_enabled] ,
    [j].[owner_name] ,
    COALESCE([j2].[shortest_duration], 'N/A') AS [shortest_duration] ,
    COALESCE([j2].[longest_duration], 'N/A') AS [longest_duration] ,
    COALESCE(CAST([j2].[last_run_date] AS VARCHAR(20)), 'N/A') AS [last_run_date] ,
    COALESCE(CAST([j2].[next_run_date] AS VARCHAR(20)), 'N/A') AS [next_run_date] ,
    COALESCE([j3].[frequency], 'N/A') AS [frequency] ,
    COALESCE([j3].[schedule], 'N/A') AS [schedule] ,
    COALESCE([j3].[schedule_detail], 'N/A') AS [schedule_detail] ,
    COALESCE(CAST([j2].[job_success] AS VARCHAR(10)), 'N/A') AS [job_success] ,
    COALESCE(CAST([j2].[job_cancel] AS VARCHAR(10)), 'N/A') AS [job_cancel] ,
    COALESCE(CAST([j2].[job_retry] AS VARCHAR(10)), 'N/A') AS [job_retry] ,
    COALESCE(CAST([j2].[job_fail] AS VARCHAR(10)), 'N/A') AS [job_fail] ,
    COALESCE(CAST([j2].[last_failure_date] AS VARCHAR(20)), 'N/A') AS [last_failure_date] ,
    COALESCE(CASE WHEN [j2].[job_fail] > 0
                       AND [j2].[operator_id_emailed] = 0
                  THEN 'No operator emailed'
                  ELSE CAST([j2].[operator_id_emailed] AS VARCHAR(100))
             END, 'N/A') AS [operator_id_emailed] ,
    [j].[log_when] ,
    [j].[email_when] ,
    [j].[operator_name] ,
    [j].[operator_email_address] ,
    [j].[is_operator_enabled]
FROM
    [#jobinfo] AS [j]
    LEFT JOIN [#jobstats] AS [j2]
    ON [j2].[job_id] = [j].[job_id]
    LEFT JOIN [#jobsched] AS [j3]
    ON [j3].[job_id] = [j].[job_id]
ORDER BY CASE WHEN [j].[is_enabled] = 'Enabled' THEN 9999999 ELSE 0 END

