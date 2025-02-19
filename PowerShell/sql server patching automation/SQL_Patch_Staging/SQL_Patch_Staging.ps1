[CmdletBinding()]
    Param
    (
        # The SQL SERVER version that is going to be patched.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNull()]
        $version

        # The RunDate from the PROCESS_SETTINGS table in ETL_Maintenance :: Required Param
        #[Parameter(Mandatory=$true,
        #           ValueFromPipelineByPropertyName=$true,
        #           Position=1)]
        #[ValidateNotNull()]
        #$RunDate 
        
    )
    
if ($version -eq "2016"){
    $versionnum ="130" 
    
} elseif ($version -eq "2014") {
   $versionnum = "120"  
  # log file isn't present at the same location?  
} elseif ($version -eq "2012") {
   $versionnum = "110"  
  
}

Write-Host "Yaaaaaas, $version $versionnum exists"

 
# This is the file that contains the list of computers you want 
$computers = gc "C:\SQL Patching\$version`servers.txt"


 
# This is the directory you want to copy to the computer (IE. c:\folder_to_be_copied)
$source = "C:\SQL Patching\Updates\SQL$version\"


# This is the list of files in your source directory 
$files = Get-ChildItem -Path $source 
 
# On the desination computer, where do you want the folder to be copied?
$dest = "c$"

# This is your start date and time
$datestart=(Get-Date -Format G)
 

Write-Host "*****$datestart - Patch Staging Started*****"
 
foreach ($computer in $computers) {
    if (test-Connection -Cn $computer -quiet) {
        # This is the path for the summary document to be copied after the deploy
        $summarypath = "\\$computer\$dest\Program Files\Microsoft SQL Server\$versionnum\Setup Bootstrap\Log\Summary.txt"
        $date = (Get-Item $summarypath).LastWriteTime.toString("MM-dd-yyyy")
        
        Remove-Item �\\$computer\$dest\Updates\SQL� -Force -Recurse -ErrorAction SilentlyContinue
        Copy-Item $source -Destination \\$computer\$dest\Updates\SQL -Recurse
        Write-Host "$computer update successfully staged to \\$computer\$dest\Updates\SQL\$files"
        
        #copying the summary file to a central location after the deploy
        Copy-Item $summarypath -Destination "\\$computer\$dest\$computer`_Summary_$date.txt" 

    } else {
        Write-Host $computer "************$computer is offline, no update staged.***************"
    }
 
}


# This is your completion date and time
$datecomplete=(Get-Date -Format G)

Write-Host "*****$datecomplete - Patch Staging Completed*****"
