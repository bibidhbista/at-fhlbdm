EXEC sys.sp_MSforeachdb 'USE [?]; SELECT * FROM sys.database_files where physical_name like ''%_old%'''
