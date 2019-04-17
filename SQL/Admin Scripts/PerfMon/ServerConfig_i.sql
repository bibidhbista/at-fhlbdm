CREATE PROCEDURE ServerConfig_i



AS



IF OBJECT_ID('tempdb..#ServerConfig') IS NOT NULL

	DROP TABLE #ServerConfig;



CREATE TABLE #ServerConfig(name nvarchar(35), minimum int, maximum int, config_value int, run_value int )



INSERT INTO #ServerConfig

EXEC sp_configure



DECLARE @date DATETIME = GETDATE()



INSERT INTO ServerConfig 

SELECT @date, @@SERVERNAME, name, config_value FROM #ServerConfig

