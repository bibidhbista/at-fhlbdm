

CREATE PROCEDURE [dbo].[FileIoStats_i]



AS



INSERT INTO FileIoStats

select 

	getdate() as DateRun, 

	@@SERVERNAME,

	DB_NAME(a.database_id) as DbName,

	CASE WHEN b.type = 1 THEN 'LOG' ELSE 'DATA' END AS FileType,

	b.physical_name, 

	CASE WHEN num_of_reads = 0 then 0 else (a.io_stall_read_ms/a.num_of_reads) end as readlatency,

	CASE WHEN num_of_writes = 0 then 0 else (a.io_stall_write_ms/a.num_of_writes) end as writelatency,

	CASE WHEN num_of_reads = 0 and num_of_writes = 0 then 0 else (a.io_stall/(a.num_of_reads + a.num_of_writes)) end as latency,

	

	--CASE WHEN num_of_reads = 0 then 0 else (a.num_of_bytes_read/a.num_of_reads) end as AvgBytesPerRead,

	--CASE WHEN num_of_writes = 0 then 0 else (a.num_of_bytes_written/a.num_of_writes) end as AvgBytesPerWrite,

	--CASE WHEN num_of_reads = 0 and num_of_writes = 0 then 0 else ((a.num_of_bytes_read + a.num_of_bytes_written)/(a.num_of_reads + a.num_of_writes)) end as AvgBytePerTransfer,



	a.num_of_reads,

	a.num_of_bytes_read,

	a.num_of_writes,

	a.num_of_bytes_written,

	a.io_stall_read_ms,

	a.IO_stall_write_ms,

	sample_ms





from sys.dm_io_virtual_file_stats(NULL,NULL) a

INNER JOIN sys.master_files b on

	a.database_id = b.database_id

	and a.file_id = b.file_id

WHERE DB_NAME(a.database_id) IN ('CorrLinks2008', 'ICON_dev', 'ICONMedical_Dev', 'Trufacs_Dev', 'Trulincs_Dev')





