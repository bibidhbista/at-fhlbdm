

Create Procedure [dbo].[Admin_DBAMonitor_ServerLevelInfo]



AS



-- SQL and OS Version information for current instance  (Query 1) (Version Info)

SELECT @@SERVERNAME AS [Server Name], @@VERSION AS [SQL Server and OS Version Info];





-- When was SQL Server installed  (Query 2) (SQL Server Install Date)  

SELECT @@SERVERNAME AS [Server Name], create_date AS [SQL Server Install Date] 

FROM sys.server_principals WITH (NOLOCK)

WHERE name = N'NT AUTHORITY\SYSTEM'

OR name = N'NT AUTHORITY\NETWORK SERVICE' OPTION (RECOMPILE);



-- Tells you the date and time that SQL Server was installed

-- It is a good idea to know how old your instance is



-- Get selected server properties (SQL Server 2012)  (Query 3) (Server Properties)

SELECT SERVERPROPERTY('MachineName') AS [MachineName], SERVERPROPERTY('ServerName') AS [ServerName],  

SERVERPROPERTY('InstanceName') AS [Instance], SERVERPROPERTY('IsClustered') AS [IsClustered], 

SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS [ComputerNamePhysicalNetBIOS], 

SERVERPROPERTY('Edition') AS [Edition], SERVERPROPERTY('ProductLevel') AS [ProductLevel], 

SERVERPROPERTY('ProductVersion') AS [ProductVersion], SERVERPROPERTY('ProcessID') AS [ProcessID],

SERVERPROPERTY('Collation') AS [Collation], SERVERPROPERTY('IsFullTextInstalled') AS [IsFullTextInstalled], 

SERVERPROPERTY('IsIntegratedSecurityOnly') AS [IsIntegratedSecurityOnly],

SERVERPROPERTY('IsHadrEnabled') AS [IsHadrEnabled], SERVERPROPERTY('HadrManagerStatus') AS [HadrManagerStatus];



-- This gives you a lot of useful information about your instance of SQL Server,

-- such as the ProcessID for SQL Server and your collation

-- The last two columns are new for SQL Server 2012





