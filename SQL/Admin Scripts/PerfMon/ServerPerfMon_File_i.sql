

CREATE PROCEDURE ServerPerfMon_File_i

	

AS



INSERT INTO ServerPerfMon

SELECT 

      CAST(CAST([CounterDateTime] AS CHAR(23)) AS DATETIME)

	  ,REPLACE(MachineName, '\\', '')

	  ,cd.CounterName

	  ,cd.InstanceName

      ,[CounterValue]

  FROM [ATGDbMon].[dbo].[CounterData] c

  INNER JOIN CounterDetails cd ON cd.CounterId = c.CounterId



TRUNCATE TABLE [ATGDbMon].[dbo].[CounterData]

TRUNCATE TABLE [ATGDbMon].[dbo].[CounterDetails]

TRUNCATE TABLE [ATGDbMon].[dbo].[DisplayToID]



