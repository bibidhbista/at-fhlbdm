SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @IndexName SYSNAME = '[PK_ExternalMessage]'; 
DECLARE @DatabaseName SYSNAME;

SELECT @DatabaseName = '[' + DB_NAME() + ']';

WITH XMLNAMESPACES
   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT
    n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS sql_text,
    n.query('.'),
    cp.plan_handle,
    i.value('(@PhysicalOp)[1]', 'VARCHAR(128)') AS PhysicalOp,
    i.value('(./IndexScan/@Lookup)[1]', 'VARCHAR(128)') AS IsLookup,
    i.value('(./IndexScan/Object/@Database)[1]', 'VARCHAR(128)') AS DatabaseName,
    i.value('(./IndexScan/Object/@Schema)[1]', 'VARCHAR(128)') AS SchemaName,
    i.value('(./IndexScan/Object/@Table)[1]', 'VARCHAR(128)') AS TableName,
    i.value('(./IndexScan/Object/@Index)[1]', 'VARCHAR(128)') as IndexName,
    i.query('.'),
    STUFF((SELECT DISTINCT ', ' + cg.value('(@Column)[1]', 'VARCHAR(128)')
       FROM i.nodes('./OutputList/ColumnReference') AS t(cg)
       FOR  XML PATH('')),1,2,'') AS output_columns,
    STUFF((SELECT DISTINCT ', ' + cg.value('(@Column)[1]', 'VARCHAR(128)')
       FROM i.nodes('./IndexScan/SeekPredicates/SeekPredicateNew//ColumnReference') AS t(cg)
       FOR  XML PATH('')),1,2,'') AS seek_columns,
    RIGHT(i.value('(./IndexScan/Predicate/ScalarOperator/@ScalarString)[1]', 'VARCHAR(4000)'), len(i.value('(./IndexScan/Predicate/ScalarOperator/@ScalarString)[1]', 'VARCHAR(4000)')) - charindex('.', i.value('(./IndexScan/Predicate/ScalarOperator/@ScalarString)[1]', 'VARCHAR(4000)'))) as Predicate,
    cp.usecounts,
    query_plan
FROM (  SELECT plan_handle, query_plan
        FROM (  SELECT DISTINCT plan_handle
                FROM sys.dm_exec_query_stats WITH(NOLOCK)) AS qs
        OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) tp
      ) as tab (plan_handle, query_plan)
INNER JOIN sys.dm_exec_cached_plans AS cp 
    ON tab.plan_handle = cp.plan_handle
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/*') AS q(n)
CROSS APPLY n.nodes('.//RelOp[IndexScan/Object[@Index=sql:variable("@IndexName") and @Database=sql:variable("@DatabaseName")]]' ) as s(i)
--WHERE i.value('(./IndexScan/@Lookup)[1]', 'VARCHAR(128)') = 1
OPTION(RECOMPILE, MAXDOP 1);


