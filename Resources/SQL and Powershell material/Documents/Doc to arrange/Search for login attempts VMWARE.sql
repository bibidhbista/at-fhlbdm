-- Search for login attempts/logouts for a specific user
DECLARE @SearchName NVARCHAR(25)
DECLARE @StartTime NVARCHAR(30)
DECLARE @EndTime NVARCHAR(30)

set @SearchName = 'Smiller'                        -- Change this to the name you want to search
set @StartTime = '10-13-2017 14:29'					-- The timeframe you want the search to start from
set @EndTime = '10-13-2017 20:01'                    -- The timeframe you want the search to end on

SELECT TOP (1000) [EventID]
      ,[Module]
      ,[EventType]
      ,[Time]
      ,[Source]
      ,[Severity]
      ,[ModuleAndEventText]
      ,[UserDisplayName]
      ,[UserSID]
      ,[DesktopId]
      ,[DesktopDisplayName]
      ,[MachineId]
      ,[PoolId]
      ,[SessionType]
  FROM [VIEW_VIM_VEDB].[dbo].[VE_user_events] WHERE [ModuleAndEventText] LIKE ('%'+@SearchName+'%') 
  AND [Time] BETWEEN @StartTime AND @EndTime


