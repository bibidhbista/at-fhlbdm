#Requires -version 3.0
add-type -AssemblyName "Microsoft.SqlServer.SqlWmiManagement, version=11.0.0.0, Culture=Neutral, PublicKeyToken=89845dcd8080cc91";
add-type -AssemblyName "Microsoft.AnalysisServices, version=11.0.0.0, Culture=Neutral, PublicKeyToken=89845dcd8080cc91";


$data_table = New-Object "system.data.datatable";
$col = New-Object "system.data.datacolumn" ('MachineName', [System.String]);
$data_table.columns.Add($col);
$col = New-Object "system.data.datacolumn" ('ServerInstance', [System.String]);
$data_table.columns.Add($col);
$col = New-Object "system.data.datacolumn" ('Type', [System.String]); #type=SQLServer / AnalysisServer / ReprtServer / IntegrationService 
$data_table.columns.Add($col);
$col = New-Object "system.data.datacolumn" ('Version', [System.String]);
$data_table.columns.Add($col);
$col = New-Object "system.data.datacolumn" ('Edition', [System.String]);
$data_table.columns.Add($col);
$col = New-Object "system.data.datacolumn" ('ServiceAccount', [System.String]);
$data_table.columns.Add($col);


[string[]]$server_list= 'sqltest2014',''; 
# [string[]]$server_list = gc -path 'c:\temp\server_list.txt' #you can put your server list in a text file, each [ServerName] uses one line

foreach ($machine_name in $server_list)
{   "processing : $machine_name"
    try 
    {
        $mc = new-object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer 'sqltest2014';
        $mc2 = $mc.services | ? {($_.type -in ("SqlServer", "AnalysisServer", "ReportServer", 'IntegrationService') ) }
        $mc2 |gm
        $mc2 | % { $s = $_.name;
            [string]$svc_acct = $_.ServiceAccount;
            switch ($_.type) 
            { "sqlserver" { if ($s.contains("$")) {$sql_instance= "$($machine_name)\$($s.split('$')[1])"} else {$sql_instance=$machine_name;} 
                                $sql_svr = new-object "microsoft.sqlserver.management.smo.server" $sql_instance;
                                $row = $data_table.NewRow;
                                $row.Edition = $sql_svr.Edition; 
                                $row.Version = $sql_svr.Version;
                                $row.Type = 'SQLServer';
                                $row.ServerInstance = $sql_instance;
                                $row.ServiceAccount = $svc_acct;
                                $row.MachineName=$machine_name;
                                $data_table.Rows.Add($row);    
                          } #sqlserver 

              "AnalysisServer"  { if ($s.contains("$")) {$as_instance= "$($machine_name)\$($s.split('$')[1])"} else {$as_instance=$machine_name;} 
                                  $as_svr = New-Object "Microsoft.AnalysisServices.Server";
                                  $as_svr.connect("data source=$as_instance");
                                  $row = $data_table.NewRow();
                                  $row.Edition = $as_svr.Edition; 
                                  $row.Version = $as_svr.Version;
                                  $row.Type = 'AnalysisServer';
                                  $row.ServerInstance = $as_instance;
                                  $row.ServiceAccount = $svc_acct;
                                  $row.MachineName=$machine_name;
                                  $data_table.Rows.Add($row);    
                                } #AnalysisServer 

              "ReportServer"  {
                                $pathname = ($mc.services[$s]).PathName;
                                $pathname= "\\$machine_name\" + ($pathname.replace(':\', '$\')).replace('"', '')
 
                                $item=get-item $pathname
                                [string]$ver='V' + ($item.VersionInfo.ProductMajorPart).ToString();
                                [string]$file_version = $item.VersionInfo.ProductVersion;
                        
                                if ($s.Contains('$')) # this is a named instance of SSRS
                                {

                                    [string]$instance_name = (($s.split('$'))[1]).replace('_', '_5f'); #SSRS instance name is encoded
                                    [string]$rs_name="RS_$($instance_name)";
                                }

                                else
                                {
                                    [string]$instance_name = 'MSSQLSERVER';
                                    [string]$rs_name='RS_MSSQLServer';
                                }

                                if ($ver -eq 'V9') 
                                {
                                #for sql 2005 SSRS, there is no direct version number from WMI interface, so I have to use SSRS executable file version info as SSRS version
                                    gwmi -class MSReportServer_Instance �Namespace �root\microsoft\sqlserver\reportserver\V9� -ComputerName $machine_name | 
                                    Where-Object {$_.__Path -like "*InstanceName=`"$($instance_name)`"" } | 
                                    % {   $row = $data_table.NewRow();
                                          $row.Edition = $_.EditionName; 
                                          $row.Version = $File_Version;
                                          $row.Type = 'ReportServer';
                                          $row.ServerInstance = $s;
                                          $row.ServiceAccount = $svc_acct;
                                          $row.MachineName=$machine_name;
                                          $data_table.Rows.Add($row);    

                                       }

                                }
                                else
                                {  
                                   gwmi -class MSReportServer_Instance �Namespace �root\microsoft\sqlserver\reportserver\$rs_name\$ver� -ComputerName $machine_name | 
                                   Where-Object {$_.__Path -like "*InstanceName=`"$($instance_name)`"" } | 
                                   %  {   $row = $data_table.NewRow();
                                          $row.Edition = $_.EditionName; 
                                          $row.Version = $_.version;
                                          $row.Type = 'ReportServer';
                                          $row.ServerInstance = $s;
                                          $row.ServiceAccount = $svc_acct;
                                          $row.MachineName=$machine_name;
                                          $data_table.Rows.Add($row);    
                                       }
                                }
                            } #ReportServer
              'SqlServerIntegrationService' {
                                                $pathname = ($mc.services[$s]).PathName;
                                                $pathname= "\\$machine_name\" + ($pathname.replace(':\', '$\')).replace('"', '');
 
                                                $item=get-item $pathname;
                                                [string]$ver= ($item.VersionInfo.ProductMajorPart).ToString() +'0';
                                                [string]$file_version = $item.VersionInfo.ProductVersion;

                                                #finding the SSIS edition by reading the registry
                                                $key="SOFTWARE\MICROSOFT\Microsoft SQL Server\$ver\Tools\Setup";
                                                $type = [Microsoft.Win32.RegistryHive]::LocalMachine;
                                                $regkey=[Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $machine_name);
                                                $r=$regkey.OpenSubKey($key).GetValue('edition');
                                              
                                                $row = $data_table.NewRow();
                                                $row.Edition = $r; 
                                                $row.Version = $file_version;
                                                $row.Type = 'IntegrationService';
                                                $row.ServerInstance = $s;
                                                $row.ServiceAccount = $svc_acct;
                                                $row.MachineName=$machine_name;
                                                $data_table.Rows.Add($row);   

                                            } #sqlserverIntegrationService 
                        
            }#switch
         
        }#where clause
    }#try
    catch
    {
        Write-Error $Error[0].Exception
    }#catch
}#foreach



$data_table | select machineName, serverinstance, type, version, edition, serviceaccount| ft -auto

#if you want to export to an csv file, you can do the following, assuming you have c:\temp\ folder
$data_table | select machineName, serverinstance, type, version, edition | export-csv -path c:\temp\test.csv -notypeinfo -Force
