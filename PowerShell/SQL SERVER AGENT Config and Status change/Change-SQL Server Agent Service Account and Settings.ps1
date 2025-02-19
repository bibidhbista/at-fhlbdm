#icm -cn ddmssis01,ddmssis01, tdmssis01,tdmssis02, udmssis01,udmssis02,pdmssis01,pdmssis02 {Get-Service|? name -eq "sqlserveragent"}





####################################
##
##  Change SQL Server Service and Agent Account and Password
##
##  If doing this for multiple server create a text file with the list of servers 
##  Additional functionality would need to be added if you want to also pass account name and password as variables but would be easy to add
##  Output will be written to screen reporting success or failure of backup
##
####################################



## create server list from comma seperated list
##$serverlist =  "<name of server>", "<name of server>", "<name of server>"

##server list from text file 
#$serverlist = Get-Content C:\serverlist.txt

$serverlist = 'ddmssis01','ddmssis01', 'tdmssis01','tdmssis02', 'udmssis01','udmssis02','pdmssis01','pdmssis02'


foreach($server in $serverlist)
    {

cd sqlserver:\sql\$server\default\JobServer\Jobs


##take a backup 
## modify the Where-Object filter if an different naming convention is used for your backup job

#$job = dir | ?{$_.name -like '*backup*' -and $_.isenabled -eq 'true'}
#$backup =$job.start()
#start-sleep -s 5
#
###display current exectution status of backup job 
#do 
#{
#"backup job running......"
#$status = dir 
#$status.refresh()
#
#$status = dir | ?{$_.name -like '*backup*' -and $_.isenabled -eq 'true'} 
#
#start-sleep -s 2
#
#} while($status.CurrentRunStatus -contains 'executing')
#
### validate that backup completed enter yes to continue if backup failed enter No exit the process
#write-host "Backup Last run outcome ----> "$status.LastRunOutcome -BackgroundColor Blue -ForegroundColor Red
#$response = read-host -Prompt "Did backupjob for '$($server)' successfully complete Y/N"
#
#if ($response -eq 'Y'){



##get sql service 
$service = get-wmiObject win32_service -computername $server | ?{$_.name -eq 'mssqlserver'} 

$agent = get-wmiObject win32_service -computername $server | ?{$_.name -eq 'SQLSERVERAGENT'} 


# change sql service account and password.  if acccount is local must put .\ in front of the account name
#$changestatus = $service.change($null,$null,$null,$null,$null,$null,"<account name>","<password>",$null, $null, $null)

$changeagent = $agent.change($null,$null,$null,$null,$null,$null,"DM\DMSQLSrvc","s@f34sql",$null, $null, $null)

## start-sleep added due to failures during testing.  this seemed to resolve the failures
start-sleep -s 2

##error handling will be written to screen to validate if account change and service restart is successful

#if($changestatus.returnvalue -eq 0)
#        {
#        write-host $server'......service change successfull' -BackgroundColor Blue -ForegroundColor White
#        }
#
#if($changestatus.returnvalue -gt 0) ##if fails see what the return value is.  this link describes the return values https://msdn.microsoft.com/en-us/library/windows/desktop/aa393660(v=vs.85).aspx
#        {
#        write-host $server'......service change successfull' -BackgroundColor red -ForegroundColor yellow
#        }
if($changeagent.returnvalue -eq 0)
        {
        write-host $server'......Agent service change successfull' -BackgroundColor green -ForegroundColor White
        }

if($changeagent.returnvalue -gt 0) ##if fails see what the return value is.  this link describes the return values https://msdn.microsoft.com/en-us/library/windows/desktop/aa393660(v=vs.85).aspx
        {
        write-host $server'......agent service change successfull' -BackgroundColor red -ForegroundColor yellow
        }

## stop service after service account change 
$stopagent = $agent.stopservice()
start-sleep -s 5

$stopservice = $service.stopservice()

## start-sleep added due to failures during testing.  this seemed to resolve the failures
Start-Sleep -s 5

if($stopservice.returnvalue -eq 0)  ##if fails see what the return value is.  this link describes the return values https://msdn.microsoft.com/en-us/library/windows/desktop/aa393660(v=vs.85).aspx
        {
    write-host $server'.....Service stopped successfully' -BackgroundColor Blue -ForegroundColor White
        }

if($stopservice.returnvalue -gt 0)
        {
    write-host $server'....Service stopped unsuccessfully' -BackgroundColor red -ForegroundColor yellow
        }
if($stopagent.returnvalue -eq 0)  ##if fails see what the return value is.  this link describes the return values https://msdn.microsoft.com/en-us/library/windows/desktop/aa393660(v=vs.85).aspx
        {
    write-host $server'.....Agent stopped successfully' -BackgroundColor green -ForegroundColor White
        }

if($stopagent.returnvalue -gt 0)
        {
    write-host $server'....Agent stopped unsuccessfully' -BackgroundColor red -ForegroundColor yellow
        }

## start service account and account change will take effect
$startservice = $service.startservice()

if($startservice.returnvalue -eq 0)
        {
    write-host $server'.....Service started successfully' -BackgroundColor Blue -ForegroundColor White
        }
if($startservice.returnvalue -gt 0)  ##if fails see what the return value is.  this link describes the return values https://msdn.microsoft.com/en-us/library/windows/desktop/aa393660(v=vs.85).aspx
        {
    write-host $server'.....service started unsuccessfully' -BackgroundColor red -ForegroundColor yellow
        }

$startagent = $agent.startservice()

if($startagent.returnvalue -eq 0)
        {
    write-host $server'.....agent started successfully' -BackgroundColor green -ForegroundColor White
        }
if($startagent.returnvalue -gt 0)  ##if fails see what the return value is.  this link describes the return values https://msdn.microsoft.com/en-us/library/windows/desktop/aa393660(v=vs.85).aspx
        {
    write-host $server'.....agent started unsuccessfully' -BackgroundColor red -ForegroundColor yellow
        }
            

    }
#else {  ## if backup failed and No is entered process will bounce to the else
#
#Write-Host "please check why backup did not complete successfully" -BackgroundColor Red -ForegroundColor blue 
#
#}
#}



###################################################################################################################################
##  validate script if you want to run and see if service is back up and running and what account it is running under #############
###################################################################################################################################

write-host ---------------------------------------------------------
write-host validate
write-host ---------------------------------------------------------

## create server list from comma seperated list
##$vserverlist =  "<name of server>", "<name of server>", "<name of server>"

#$vserverlist = 'ddmssis01','ddmssis01', 'tdmssis01','tdmssis02', 'udmssis01','udmssis02','pdmssis01','pdmssis02'
$vserverlist = 'atgdsmsq14','atgdsmsq17'
foreach($vserver in $vserverlist)
    {
    ##get sql service 
$vservice = get-wmiObject win32_service -computername $vserver | ?{$_.name -eq 'mssqlserver'} 

$vagent = get-wmiObject win32_service -computername $vserver | ?{$_.name -eq 'SQLSERVERAGENT'} 


#if($vagent.state -eq "stopped"){
write-host "Agent is stopped in:"
$vserver
$vservice.state
$vservice.startname
$vagent.state
$vagent.startname
write-host --------------------------------------

#}

}
