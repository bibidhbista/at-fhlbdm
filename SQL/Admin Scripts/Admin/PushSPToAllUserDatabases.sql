CREATE PROCEDURE dbo.PushSPToAllUserDatabases

--Drops and creates SP from @DBName to all user databases

	@DBName sysname,

	@SPName VARCHAR(128)

AS



DECLARE @ProcTbl TABLE (txt VARCHAR(8000))

DECLARE @ProcTxt VARCHAR(8000), @DropTxt VARCHAR(8000)

DECLARE @SQL VARCHAR(8000)



SELECT @DropTxt = '

USE @db;



EXEC (''

IF EXISTS(SELECT * FROM sys.objects WHERE name = ''''' + @SPName + ''''' AND Type = ''''P'''')

BEGIN

	DROP PROCEDURE ' + @SPName + '

END

'')

'





SELECT @SQL = '

USE ' + @DBName + ';



EXEC (''

	SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID(''''' + @SPName + ''''')

'')

'



INSERT INTO @ProcTbl EXEC(@SQL)

IF EXISTS(SELECT * FROM @ProcTbl)

BEGIN

	

	SELECT @ProcTxt = txt FROM @ProcTbl

	SELECT @ProcTxt = REPLACE(@ProcTxt, '''', '''''')

	SELECT @ProcTxt = '

	USE @db;

	

	EXEC (''

	' + @ProcTxt + '

	'')

	'

	

	DECLARE DBCursor CURSOR FOR

	SELECT name FROM sys.databases

	WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb')

	

	OPEN DBCursor

	

	FETCH NEXT FROM DBCursor INTO @DBName

	

	WHILE (@@FETCH_STATUS = 0)

		 BEGIN

			DECLARE @DBDropTxt VARCHAR(8000) = REPLACE(@DropTxt, '@db', @DBName)

			DECLARE @DBProcTxt VARCHAR(8000) = REPLACE(@ProcTxt, '@db', @DBName)

			

			EXEC(@DBDropTxt)

			EXEC(@DBProcTxt)

			FETCH NEXT FROM DBCursor INTO @DBName		

		 END

	

	CLOSE DBCursor

	DEALLOCATE DBCursor



END



