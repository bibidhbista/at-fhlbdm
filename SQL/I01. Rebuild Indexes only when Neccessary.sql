USE [CCA_InmateKiosk_Dev]
GO
/****** Object:  StoredProcedure [dbo].[Admin_ReIndex_WhenNeeded]    Script Date: 7/10/2018 3:07:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[Admin_ReIndex_WhenNeeded]        
        
AS        
        
declare @DumpSizeThreshold int        
declare @scandensitypages int        
declare @logicalfragpages int        
declare @ScanDensityThreshold int        
declare @LogFragThreshold int        
declare @CurDt datetime      
declare @StopDt datetime                    
declare @MaxMinutesToRun int        
declare @BeginDt datetime, @EndDt datetime
  
set @MaxMinutesToRun = 60        
      
set @CurDt = convert(datetime, convert(varchar(11), getdate()))        
set @StopDt = dateadd(n, @MaxMinutesToRun, getdate())       
      
      
-- Cleanup up _IndexStatsTableNameHistory & _IndexStatsHistory (We Only Keep 120 Days)      
Delete from _IndexStatsTableNameHistory where StartDt < DATEADD(day,-120,GetDate())      
Delete from _IndexStatsHistory where DateRun <DATEADD(day,-120,GetDate())      
      
--threshold to monitor stats        
--scandensity only relevant to tables with more than 1000 pages        
--logical fragmentation only relevant to tables with more than 8 pages (1 extent)        
set @scandensitypages = 1000        
set @logicalfragpages = 64        
set @ScanDensityThreshold = 80        
set @LogFragThreshold = 20        
set @DumpSizeThreshold = 50000000        
        
DECLARE cur CURSOR        
KEYSET        
FOR         
        
select         
 objectname,         
 'ALL' as indexname,         
 dpages*8 as DumpSize,        
 case when pages>@scandensitypages then convert(decimal(5,2), scandensity) else 100 end as scandensity,         
 case when pages>@logicalfragpages then convert(decimal(5,2), logicalfragmentation) else 0 end as logicalfragmentation         
from _IndexStatsHistory        
 inner join sysobjects so on        
 objectname = so.name        
 inner join sysindexes si on        
 so.id = si.id and        
 indexname = si.name         
where daterun > @CurDt-1 and daterun < @CurDt and        
 (case when pages>@logicalfragpages then logicalfragmentation else 1 end >= @LogFragThreshold or        
  case when pages>@scandensitypages then scandensity else 99 end <= @ScanDensityThreshold) and indexid=1        
        
UNION        
        
select         
 objectname,         
 indexname,         
 dpages*8 as DumpSize,        
 case when pages>@scandensitypages then convert(decimal(5,2), scandensity) else 100 end as scandensity,         
 case when pages>@logicalfragpages then convert(decimal(5,2), logicalfragmentation) else 0 end as logicalfragmentation         
from _IndexStatsHistory        
 inner join sysobjects so on        
 objectname = so.name        
 inner join sysindexes si on        
 so.id = si.id and        
 indexname = si.name         
where daterun > @CurDt-1 and daterun < @CurDt and        
 (case when pages>@logicalfragpages then logicalfragmentation else 1 end >= @LogFragThreshold or        
  case when pages>@scandensitypages then scandensity else 99 end <= @ScanDensityThreshold) and        
  objectname not in        
  (select objectname        
  from _IndexStatsHistory        
  where daterun > @CurDt-1 and daterun < @CurDt and        
   (case when pages>@logicalfragpages then logicalfragmentation else 1 end >= @LogFragThreshold or        
   case when pages>@scandensitypages then scandensity else 99 end <= @ScanDensityThreshold) and indexid=1        
   )        
order by scandensity, logicalfragmentation desc        
        
        
DECLARE @ssql varchar(255)        
DECLARE @TblName varchar(255)        
DECLARE @IdxName varchar(255)        
DECLARE @DumpSize int        
DECLARE @ScanDensity decimal(5,2)        
DECLARE @LogicalFrag decimal(5,2)        
DECLARE @TotalSize int        
        
SET @TotalSize=0        
        
OPEN cur        
        
IF @@rowcount = 0        
 BEGIN        
  CLOSE cur        
  DEALLOCATE cur        
  DECLARE cur CURSOR        
  KEYSET 
  FOR         
  select         
   objectname,         
   'ALL' as indexname,         
   dpages*8 as DumpSize,        
   case when pages>@scandensitypages then convert(decimal(5,2), scandensity) else 100 end as scandensity,         
   case when pages>@logicalfragpages then convert(decimal(5,2), logicalfragmentation) else 0 end as logicalfragmentation         
  from _IndexStatsHistory        
  inner join sysobjects so on        
  objectname = so.name        
  inner join sysindexes si on        
  so.id = si.id and        
     indexname = si.name         
  where daterun > @CurDt-1 and daterun < @CurDt and        
   (case when pages>@logicalfragpages then logicalfragmentation else 1 end >= @LogFragThreshold or        
    case when pages>@scandensitypages then scandensity else 99 end <= @ScanDensityThreshold) and indexid=1        
        
  UNION        
        
  select         
   objectname,         
   indexname,         
   dpages*8 as DumpSize,        
   case when pages>@scandensitypages then convert(decimal(5,2), scandensity) else 100 end as scandensity,         
   case when pages>@logicalfragpages then convert(decimal(5,2), logicalfragmentation) else 0 end as logicalfragmentation         
  from _IndexStatsHistory        
  inner join sysobjects so on        
  objectname = so.name        
  inner join sysindexes si on        
  so.id = si.id and        
  indexname = si.name         
  where daterun > @CurDt-1 and daterun < @CurDt and        
   (logicalfragmentation >= @LogFragThreshold or        
    scandensity <= @ScanDensityThreshold) and        
    objectname not in        
    (select objectname        
    from _IndexStatsHistory        
    where daterun > @CurDt-1 and daterun < @CurDt and        
     (logicalfragmentation >= @LogFragThreshold or        
     scandensity <= @ScanDensityThreshold) and indexid=1        
     )        
  order by scandensity, logicalfragmentation desc          
          
  OPEN cur        
 END        
        
FETCH NEXT FROM cur INTO @TblName, @IdxName, @DumpSize, @ScanDensity, @LogicalFrag        
WHILE (@@fetch_status <> -1)        
BEGIN        
 IF (@@fetch_status <> -2)        
 BEGIN        
        
  IF (@TotalSize = 0 or (@TotalSize + @DumpSize) < @DumpSizeThreshold)       
  -- AND @TblName NOT IN ('CreditUsage_Old','IncMsgActions_Old','IncomingMsgs_Old','OutGoingMsgs_Old','OutMsgActions_Old','OutMsgRecipients_Old', 'UnitCreditTrans_Old','IncomingMsgs','OutgoingMsgs','IncMsgActions','OutMsgActions','OutMsgRecipients')     
  
  AND @StopDt > getdate()      
        
   BEGIN        
	-- Date/Time Stamp Before performing the ReIndex -- 
    Set @BeginDt = GETDATE() -- Before Starting the ReIndex  
	-- set @ssql = 'DBCC DBReindex (' + rtrim(@TblName) + ', ''' + rtrim(@IdxName) + ''') WITH NO_INFOMSGS'
	set @ssql = 'ALTER INDEX ' + rtrim(@IdxName) + ' ON ' + rtrim(@TblName) + ' REBUILD WITH (FILLFACTOR = 90);'        
	exec (@ssql)  
  	-- set @ssql = 'Insert INTO _IndexStatsTableNameHistory Values (' + '''' + rtrim(@TblName) + '''' + ',' + '''' + rtrim(@IdxName) + '''' + ',' + '''' + CAST(@BeginDt AS varchar(25)) + '''' + ',' + '''' + CAST(GetDate() AS varchar(25)) + '''' + ')'      
        
	-- PRINT (@ssql)           
    Set @EndDt = GETDATE() -- After the ReIndex
    INSERT INTO _IndexStatsTableNameHistory  (TableNm, IndexNm, StartDt, EndDt) Values (@TblName, @IdxName, @BeginDt, @EndDt) 
    SET @TotalSize = @TotalSize + @DumpSize        
      
   END        
         
 END        
 FETCH NEXT FROM cur INTO @TblName, @IdxName, @DumpSize, @ScanDensity, @LogicalFrag        
END        
        
CLOSE cur        
DEALLOCATE cur        
        

