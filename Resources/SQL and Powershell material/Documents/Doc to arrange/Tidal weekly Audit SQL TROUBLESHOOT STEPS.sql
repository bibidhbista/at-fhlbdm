-- GENERAL
SELECT * FROM [dbo].[Processes] WHERE [Name] LIKE '%tida%' -- tidal weekly id = 55
SELECT * FROM  [dbo].[Process_Settings] WHERE [Process_ID]=55 --opemail & tech email
SELECT * FROM  [dbo].[Processes_Log] WHERE [Process_ID] =55 ORDER BY  [Start_Datetime] DESC 
SELECT * FROM [dbo].[Processes_Task_Detail]  WHERE PROCEss_task_name LIKE '%tidal%weekly%'  ORDER BY [Process_Task_Start_DateTime] DESC

------------------------------------------------TIDAL WEEKLY AUDIT LOG SSIS PACKAGE -------------------------------------------------
-- GEN PROCESSLOGID: 
EXECUTE usp_Get_Processes_Log_ID 
@Process_Name = 'Tidal Weekly Audit Log', --packagename 
@Process_Run_Date = null, -- pulls today's date as date getdate()
@Processes_Log_ID = OUTPUT -- outputs a new PROCESSLOGID For the process. Here, it'd be Tidal weekly audit log.


-- Get the Settings for TIDAL WEEKLY AUDIT LOG PROCESS 
EXECUTE usp_Get_Process_Settings
@Processes_Log_ID = ?, -- newly generated above... if ran with 0 or null an Id would be automatically provided through sp
@Process_Name = ? -- TIDAL WEEKLY .... if manually ran .. put 0 

-- SET VAR VB SCRIPT pulls in from settings to a variable for use in ssis package


-------------------------------------------------------------------------REPORTAUTOGENMULTRPT----------------------------------------------------
					-- report multi get rundate -- connect to  DWH3 Server
					SELECT     CD_CURRENT_DATE2 AS FullDatefromquery -- last bus date
					FROM         dbo.CDS

					--gen processes log id 
					EXECUTE usp_Get_Processes_Log_ID ?, ?, ? OUTPUT, ? --packagename,rundate=prevbusdate, pulls in username, OUTPUTS NEW PROCESS LOG ID FOR the process

					-- sql task crete report ids RS -- only checks the one that are enabled for automation on ReportsAutomated Table
					SELECT TOP (1000) [ReportID],[SourcePath],[DestPath],[FileNameStemWoExt],[FileExt],[ReportFormat],[Email],[ReportType],[ProcessId],[IsEnabled]
					  FROM [ETL_Maintenance].[dbo].[ReportsAutomated]
					-- Filtered from above for tidal job
					SELECT   *,ReportID FROM dbo.ReportsAutomated a inner JOIN dbo.Processes b on a.ProcessId=b.id
					WHERE      [a].[FileNameStemWoExt] LIKE '%tidal%' and
					--b.name= ?--and
					a.IsEnabled = 'TRUE'


					-- takes the report Id from above to pull in configs one rpt per loop
					---------------DATA FLOW TASK----------------------------
								-- oled bget report config
								exec [dbo].[usp_ReportAutoGenDS] 
								@ReportId = ? , @Processes_Log_ID = ? -- reportId from above query --processs log id for the specific process REPORTMULTIGEN

								-- script comp: Calls report service from the prev steps' config settings
								-- copies from the current report server(source) to filepath (destpath) from the setting/config of prev step
					------------------------------------------------------------

					-- updates rundate on process settings but this job/process doesn't have a rundate field to update on process_setting

					-- Logs end of process RPTMULTIGEN to Process_log or Process_error_log table

-------------------------------------------------------END OF RPTAUTOMULTIGEN--------------------------------------------------------------------------------------------------


---Contd TIDAL WEEKLLY AUDIT SSIS PACKAGE ---


-- sucess                            or						failure
-- log in processes log									log in proceses error log
-- send email											send email




--- ON POST EXECUTE OF THE TIDAL WEEKLY PACKAGE

/* calls sp to insert into processes task detail

[usp_Insert_Into_Processes_Task_Detail] 


    @Process_Log_ID numeric(18, 0),					Process_Log::ActualContainerStartTime,
	@Process_Task_Name varchar(255),				Process_Log::ContainerPath,						Process_Log::PackageTasks
	@Start_Datetime datetime = Null,				Process_Log::ActualContainerStartTime,
	@End_Datetime datetime = Null,					Process_Log::ActualContainerEndTime,
	@Process_Task_Note varchar(500) = NULL			Process_Log::ContainerTaskNotes					Process_Log::PackageNotes


*/










SELECT * FROM [dbo].[Processes_Task_Detail] WHERE [Process_Task_Name] LIKE '%reportautogen%' ORDER BY [Process_Task_Start_DateTime] DESC
SELECT * FROM  [dbo].[Processes_Log] WHERE [Process_ID] =8 ORDER BY  [Start_Datetime] DESC 
SELECT * FROM  [dbo].[Processes_Log] WHERE [ID] = '1013387'1013378
