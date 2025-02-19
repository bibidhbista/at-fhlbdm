[CmdletBinding()]
    Param
    (
        # The SQL SERVER version that is going to be patched.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNull()]
        [ValidateSet('2016','2014','2012')]
        $targetYear
  
    )


# List of all the servers
[string] $Server= 'sqltest2016'
[string] $Database = 'test_patching'
$servers = (Invoke-SQLCmd "SELECT servername as server  FROM [$Database].[dbo].[serverlist] WHERE sql_ver = '$targetYear'"  -ServerInstance $Server -Database $Database).server


# This is your start date and time
$datestart=(Get-Date -Format G)
# To check if the version from the table matches the version number based on year
if ($targetYear -eq '2016'){
    $versionFromYear ='130'
}elseif ($targetYear-eq '2014'){
    $versionFromYear ='120'
}elseif ($targetYear-eq '2012'){
    $versionFromYear ='110'
}




# List of standar servers for the provided version year
$StandardServers = (Invoke-SQLCmd "SELECT servername as server  FROM [$Database].[dbo].[serverlist] WHERE sql_ver = '$targetYear' and environment not in ('p','h')" -ServerInstance $Server -Database $Database).server


# if Prod/DR server : add to exception table
# List of exception servers and add them to exception table      
$query = ("USE $Database "+
         "TRUNCATE TABLE exception_table; "+
         "INSERT INTO exception_table(servername) "+
         "SELECT servername FROM serverlist "+
         "WHERE environment in ('p','h');")
$excpetionServerName = Invoke-SQLCmd $query -ServerInstance $Server -Database $Database



Write-Host "`n`n*****$datestart - Patch Staging Started*****"
$Database='master'
# Stage the file remotely. Remote Execution. Copy the summary file.
foreach ($computer in $servers) {
 
    if (test-Connection -Cn $computer -quiet) {
       
        # Version check
        echo "`n--------------Patching started for $computer---------------"

        $ver= (Invoke-SQLCmd "SELECT SERVERPROPERTY('ProductVersion') AS Version" -ServerInstance $computer -Database $Database).Version
       
        $version = $ver.Substring(0,2)+"0"
        if($versionFromYear -ne $version){Write-Error 'Version number from table doesn''t match the actual version number of the server.' -ErrorAction Stop}
        
        # This is the directory you want to copy to the computer (IE. c:\folder_to_be_copied)
        $source = "C:\SQL Patching\Updates\SQL$targetYear\"
        # On the desination computer, where do you want the folder to be copied?
        $dest = "\\$computer\C$\Updates\SQL"
        # This is the list of files in your source directory 
        $files = Get-ChildItem -Path $source
        
        
               
        # Stage the files on the remote server 
        try{
            Remove-Item $dest -Force -Recurse -ErrorAction SilentlyContinue
            Copy-Item $source -Destination $dest -Recurse
            Write-Host "Update successfully staged to $dest\$files" -BackgroundColor Green
        }
        catch{
            $ErrorActionPreference ="STOP"
             $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Error "ERROR: Staging failed to $dest\$files `n`n`n  $errormessage $faileditem" 
        }
               
       
        $pathexp = "C:\Updates\SQL"
        
        #pass the path to std_deploy and exc_deploy
         
        .$PsScriptRoot\Deploy-StandardPatch.ps1 -path $pathexp -computerName $computer


        # .$PsScriptRoot\Deploy-ExceptionPatch.ps1 -path $pathexp
           
          
          
          ##############################################wait for installation to complete###############################################
       

        
        # This is the path for the summary document to be copied after the deploy
        $summarypath = "\\$computer\C`$\Program Files\Microsoft SQL Server\$version\Setup Bootstrap\Log\Summary.txt"
      
        $dateCreated = (Get-Item $summarypath).LastWriteTime.toString("MM-dd-yyyy")
        
        

        #??????????????????????????????????????? WHERE IS THE CENTRAL LOCATION ????????????????????????????????????????????????? \\oak\information technology\data management\



        #copying the summary file to a central location after the deploy
        try{
            $destination = "\\$computer\C$\SQL_$targetyear\$computer`_Summary_$dateCreated.txt"
            New-Item -ItemType File -Path $destination -Force | out-null
            Copy-Item $summarypath -Destination $destination -Force
           
            Write-Host "Summary file copied to $destination" -BackgroundColor Green
            }
        catch{
            $ErrorActionPreference ="STOP"
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Error "ERROR: Summary file couldn't be copied to $destination `n`n $ErrorMessage" 
            }

        # Version Checking after the patch installation
        Echo "`n***************Previous Version: $ver********************"
        
        $patchVer= (Invoke-SQLCmd "SELECT SERVERPROPERTY('ProductVersion') AS Version" -ServerInstance $computer -Database $Database).Version
        Echo "**********Current Version (After Patching): $patchVer************"

        if($patchVer -eq $ver){
            Write-Host "WARNING: The version number before and after the patching are the same. Make sure that an updated patch is being staged." -BackgroundColor Yellow
        }


    } else {
        Write-Host $computer "************$computer is offline, no update staged.***************`n`n" -BackgroundColor Red
    }
    echo "------------Patching finished for $computer--------------------`n"
}


# This is your completion date and time
$datecomplete=(Get-Date -Format G)

Write-Host "*****$datecomplete - Patch Staging Completed*****`n`n"
 
