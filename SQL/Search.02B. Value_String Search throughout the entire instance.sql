-- Looks inside every databases' every tables' every column for the specified value

CREATE TABLE ##results (
				  columnname NVARCHAR(370),
				  DatabaseName Nvarchar (25),
				  columnvalue NVARCHAR(3630)
		  )

-- Churn through every table in every database
exec sp_msforeachdb 'use [?];
DECLARE @SEARCHSTR NVARCHAR(max)
SET @SEARCHSTR =''insulin''-- change this to your search string to find
BEGIN
		  

		  SET nocount ON;

		  DECLARE @TableName NVARCHAR(256),
		  @ColumnName NVARCHAR(128),
		  @SearchStr2 NVARCHAR(110)
		  
		  SET @TableName = ''''
		  set @searchstr2 = ''''''%'' +@searchstr +''%'''''' 
		   		  
		  WHILE @TableName IS NOT NULL
		   BEGIN
			  SET @ColumnName = ''''
			  
			  SET @TableName = (SELECT Min(Quotename(table_schema) + ''.''
								+ Quotename(table_name))
			  FROM information_schema.tables
			  WHERE table_type = ''BASE TABLE'' AND Quotename(table_schema) + ''.''	+Quotename(table_name) > @TableName
			                   AND Objectproperty(Object_id(Quotename(table_schema) +''.''+ Quotename(table_name)),''IsMSShipped'') =	0)
		   
					  WHILE ( @TableName IS NOT NULL ) AND ( @ColumnName IS NOT NULL )
						  BEGIN
							  SET @ColumnName = (SELECT Min(Quotename(column_name))
							  FROM information_schema.columns
							  WHERE table_schema = Parsename(@TableName, 2
									)
									AND table_name = Parsename(@TableName,
									1)
									AND data_type IN ( ''char'', ''varchar'',''nchar'',''nvarchar'')
									AND Quotename(column_name)>@ColumnName)
									

								IF @ColumnName IS NOT NULL
									  BEGIN
											
											  INSERT INTO ##results
											  EXEC (''
													  SELECT
													  ''''''+ @TableName+''.''+@ColumnName+'''''', DB_Name() as DatabaseName,
													  left('' +@Columnname+ '',3630) from ''+@tablename+ ''(NOLOCK)''  +
													'' WHERE''+ @Columnname +'' LIKE ''+@SearchStr2)
									   END
						END
						
		   END
		  
END
'

-- Display results
SELECT DatabaseName,columnname,columnvalue FROM ##results where databasename != 'tempdb'
Select Count(databaseName) as [Number of Matches] from ##results
DROP TABLE ##results

