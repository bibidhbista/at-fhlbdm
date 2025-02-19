SET NOCOUNT ON

/*

*/

DECLARE @command varchar(1000) 
DECLARE @searchString varchar(100) 
DECLARE @searchStringXType varchar(100) 

Create table ##gTable ([count] int);


-- keyword lookup
Set @searchString ='VulnDevices'
Set @searchStringXType ='U'     -- change this to P for stored proc, U for User Table, V for view, FN Function, IF


-- only display non-empty results 
SELECT @command =	'USE ?; DECLARE @count int; 
					IF EXISTS (SELECT ''?'' as [Database Name],name as [Table Name] FROM sysobjects WHERE xtype = '''+@searchStringXType+''' and name like ''%'+@searchString+'%'')
					BEGIN
						insert into ##gTable values (''1'')
						SELECT ''?'' as [Database Name],name as [Table Name] FROM sysobjects WHERE xtype = '''+@searchStringXType+'''and name like ''%'+@searchString+'%''
					END
					;' 
-- run against all databases on the instance
exec sp_msforeachdb @command 



-- Returns the total number of matches for the table name in the given SQL SERVER Instance
select count([count]) as [Total Table Name Search Matches]from ##gTable (nolock)

-- Drop temp table
drop table ##gTable

--select * from sysobjects


