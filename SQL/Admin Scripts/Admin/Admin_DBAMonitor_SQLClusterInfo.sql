

Create Procedure [dbo].[Admin_DBAMonitor_SQLClusterInfo]



AS





-- Get information about your cluster nodes and their status  (Query 16) (Cluster Node Properties)

-- (if your database server is in a failover cluster)

SELECT NodeName, status_description, is_current_owner

FROM sys.dm_os_cluster_nodes WITH (NOLOCK) OPTION (RECOMPILE);



-- Knowing which node owns the cluster resources is critical

-- Especially when you are installing Windows or SQL Server updates

-- You will see no results if your instance is not clustered





-- Get information about any AlwaysOn AG cluster this instance is a part of (Query 17) (AlwaysOn AG Cluster)

SELECT cluster_name, quorum_type_desc, quorum_state_desc

FROM sys.dm_hadr_cluster WITH (NOLOCK) OPTION (RECOMPILE);







